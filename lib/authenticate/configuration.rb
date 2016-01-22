module Authenticate
  class Configuration

    # ActiveRecord model class name that represents your user.
    # Specify as a String. Defaults to '::User'.
    # To set to a different class:
    #
    #   Authenticate.configure do |config|
    #     config.user_model = 'BlogUser'
    #   end
    #
    # @return [String]
    attr_accessor :user_model

    # Name of the session cookie Authenticate will send to client browser.
    # Defaults to 'authenticate_session_token'.
    # @return [String]
    attr_accessor :cookie_name

    # A lambda called to set the remember token cookie expires attribute. Defaults to 1 year expiration.
    # Note this is NOT the session's max lifetime, see #max_session_lifetime.
    # To set cookie expiration yourself:
    #
    #   Authenticate.configure do |config|
    #     config.cookie_expiration = { 1.month.from_now.utc }
    #   end
    #
    # @return [Lambda]
    attr_accessor :cookie_expiration

    # The domain to set for the Authenticate session cookie.
    # Defaults to nil, which will cause the cookie domain to set
    # to the domain of the request.
    # @return [String]
    attr_accessor :cookie_domain

    # Crypto used when authenticating and setting passwords.
    # Defaults to {Authenticate::Model::BCrypt}.
    # Crypto implementations must provide:
    #   * match?(secret, encrypted)
    #   * encrypt(secret)
    #
    # @return [Module #match? #encrypt]
    attr_accessor :crypto_provider

    # Invalidate the session after the specified period of idle time.
    # Defaults to nil, which is no idle timeout.
    #
    #   Authenticate.configure do |config|
    #     config.timeout_in = 45.minutes
    #   end
    #
    # @return [ActiveSupport::CoreExtensions::Numeric::Time]
    attr_accessor :timeout_in

    # Allow a session to 'live' for no more than the given elapsed time, e.g. 8.hours.
    # Defaults to nil, or no max session time.
    # @return [ActiveSupport::CoreExtensions::Numeric::Time]
    attr_accessor :max_session_lifetime

    # Number of consecutive bad login attempts allowed.
    # Default is nil, which disables this feature.
    # @return [Integer]
    attr_accessor :max_consecutive_bad_logins_allowed

    # Time period to lock an account for if the user exceeds
    # max_consecutive_bad_logins_allowed (and it's set to nonzero).
    # If set to nil, account is locked out indefinitely.
    # @return [ActiveSupport::CoreExtensions::Numeric::Time]
    attr_accessor :bad_login_lockout_period

    # Strategy for authentication.
    #
    # Available strategies:
    #   :email - requires user have attribute :email
    #   :username - requires user have attribute :username
    # Defaults to :email. To set to :username:
    #   Configuration.configure do |config|
    #     config.authentication_strategy = :username
    #   end
    #
    # Or, you can plug in your own authentication class, eg:
    #   Configuration.configure do |config|
    #     config.authentication_strategy = MyFunkyAuthClass
    #   end
    # @return [Symbol or Class]
    attr_accessor :authentication_strategy


    # Enable debugging messages.
    # @private
    # @return [Boolean]
    attr_accessor :debug

    # An array of additional modules to load into the User module.
    # Defaults to an empty array.
    # @return [Array]
    attr_accessor :modules


    def initialize
      # Defaults
      @debug = false
      @cookie_name = 'authenticate_session_token'
      @cookie_expiration =  -> { 1.year.from_now.utc }
      @modules = []
      @user_model = '::User'
      @authentication_strategy = :email
    end

    def user_model_class
      @user_model_class ||= user_model.constantize
    end


    # List of symbols naming modules to load.
    def modules
      modules = @modules.dup # in case the user pushes any on
      modules << @authentication_strategy
      modules << :db_password
      modules << :trackable  # needs configuration
      modules << :timeoutable if @timeout_in
      modules << :lifetimed if @max_session_lifetime
      modules << :brute_force if @max_consecutive_bad_logins_allowed
      modules
    end


  end # end of Configuration class


  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end

end
