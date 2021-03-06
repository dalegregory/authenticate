# Callback to check that the session has been authenticated.
#
# If user failed to authenticate, toss them out.
Authenticate.lifecycle.after_authentication name: 'authenticatable' do |_user, session, _opts|
  throw(:failure, I18n.t('callbacks.authenticatable.failure')) unless session && session.logged_in?
end
