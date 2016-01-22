# Authenticate

A Rails authentication gem.

Authenticate is small, simple, but extensible. It has highly opinionated defaults but is
open to significant modification.

Authenticate is inspired by, and draws from, Devise, Warden, Authlogic, Clearance, Sorcery, and restful_authentication.


## Install

Installation is pretty standard. Authenticate does not currently have an automated install process. One is coming.

* Include `Authenticate::User` into your `User` model.
* Include `Authenticate::Controller` into your `ApplicationController`
* Add an initializer: config/intializers/authenticate.rb containing:
    Authenticate.configure do |config|
      # any settings you wish to tweak, see below
    end
* Create a migration for any Authenticate features you wish to take advantage of. Here's a good default:
    `rails g migration AddAuthenticateToUsers email:string encrypted_password:string session_token:string 
    session_expiration:datetime sign_in_count:integer last_sign_in_at:datetime last_sign_in_ip:string 
    last_access_at:datetime current_sign_in_at:datetime current_sign_in_ip:string`


## Configure

Override any of these defaults in your application `config/initializers/authenticate.rb`.

```ruby
Authenticate.configure do |config|
    config.user_model = 'User'
    config.cookie_name = 'authenticate_session_token'
    config.cookie_expiration = { 1.year.from_now.utc }
    config.cookie_domain = nil
    config.crypto_provider = Bcrypt
    config.timeout_in = nil  # 45.minutes
    config.max_session_lifetime = nil  # 8.hours
    config.max_consecutive_bad_logins_allowed = nil # 5
    config.bad_login_lockout_period = nil # 5.minutes
    config.authentication_strategy = :email
```



### timeout_in

* timeout_in: the interval to timeout the user session without activity.

If your configuration sets timeout_in to a non-nil value, then the last user access is tracked.
If the interval between the current access time and the last access time is greater than timeout_in,
the session is invalidated. The user will be prompted for authentication again.



### max_session_lifetime

* max_session_lifetime: the maximum interval a session is valid, regardless of user activity.

If your configuration sets max_session_lifetime, a User session will expire once it has been active for
max_session_lifetime. The user session is invalidated and the next access will will prompt the user for
authentication again.



### max_consecutive_bad_logins_allowed & bad_login_lockout_period

* max_consecutive_bad_logins_allowed: an integer
* bad_login_lockout_period: a ActiveSupport::CoreExtensions::Numeric::Time

To enable brute force protection, set max_consecutive_bad_logins_allowed to a non-nil positive integer.
The user's consecutive bad logins will be tracked, and if they exceed the allowed maximumm the user's account
will be locked. The lock will last `bad_login_lockout_period`, which can be any time period (e.g. `10.minutes`).  



### authentication_strategy

The default authentication strategy is :email. This requires that your User model have an attribute named `email`.
The User account will be identified by this email address. The strategy will add email attribute validation to
the User, ensuring that it exists, is properly formatted, and is unique.

You may instead opt for :username. The username strategy will identify users with an attribute named `username`.
The strategy will also add username attribute validation, ensuring the username exists and is unique.


## Use

### Authentication

To perform authentication use:

* authenticate(params) - authenticate a user with credentials in params, return user if correct. 
`params[:session][:email]` and `params[:session][:password]` are required for the :email authentication
strategy. `params[:session][:username]` and `params[:session][:password]` are required for
the :username authentication strategy.

* login(user, &block) - log in the just-authenticated user. Login will run all rules as provided in the configuration,
such as timeout_in detection, max_session_lifetime, etc. You can provide a block to this method to handle the result.
Your block will receive either {SuccessStatus} or {FailureStatus}.

An example session controller:

```ruby
class SessionsController < ActionController::Base
  include Authenticate::Controller

  def create
    user = authenticate(params)
    login(user) do |status|
      if status.success?
        flash[:notice] = 'You successfully logged in! Very nice.'
        logger.info flash[:notice].inspect
        redirect_to '/'
      else
        flash[:notice] = status.message
        logger.info flash[:notice].inspect
        render template: 'sessions/new', status: :unauthorized
      end
    end
  end


  def new
  end

  def destroy
    logout
    redirect_to '/', notice: 'You logged out successfully'
  end
end
```


### Access Control

Use the `require_authentication` filter to control access to controller actions.

```ruby
class ApplicationController < ActionController::Base
    before_action :require_authentication
end
```


### Helpers

Use `current_user` and `authenticated?` in controllers, views, and helpers.

Example:

```erb
<% if authenticated? %>
  <%= current_user.email %>
  <%= button_to "Sign out", sign_out_path, method: :delete %>
<% else %>
  <%= link_to "Sign in", sign_in_path %>
<% end %>
```

### Logout

Log the user out. The user session_token will be deleted from the database, and the session cookie will
be deleted from the user's browser session.

```ruby
# in session controller...
def destroy
  logout
  redirect_to '/', notice: 'You logged out successfully'
end
```


## Extending Authenticate

Authenticate can be extended with two mechanisms:

* user modules: add behavior to the user model
* callbacks: add login during various authentication events, during login and access



### User Modules

Add behavior to your User model for your callbacks to use. Include them yourself directly in your User class,
or via the Authentication configuration. 

Example:
```ruby
Authenticate.configuraton do |config|
  config.modules = [MyUserModule]
end
```


### Callbacks

Callbacks can be added with `after_set_user` or `after_authentication`. See {Authenticate::Lifecycle} for full details.

Callbacks can `throw(:failure, message)` to signal an authentication/authorization failure, or perform
actions on the user or session. Callbacks are passed a block at runtime of `|user, session, options|`.


Example that counts logins for users. It consists of a module for User, and a callback that is
set in the `included` block. The callback is then added to the  User module via the Authenticate configuration.

```ruby
module LoginCount
  extend ActiveSupport::Concern

  included do
    # authentication hook
    Authenticate.lifecycle.after_authentication name:'login counter' do |user, session, options|
      user.count_login if user
    end
  end

  def count_login
    self.login_counter += 1
  end
end

Authenticate.configiration do |config|
  config.modules = [LoginCount]
end
```



## Testing

Authenticate has been tested with rails 4.2, other versions to follow.

## License

This project rocks and uses MIT-LICENSE.


