module Authenticate
  module Testing

    # Helpers for view tests/specs.
    #
    # Use login_as to log in a user for your test case, which allows
    # `current_user`, `logged_in?` and `logged_out?` to work properly in your test.
    module ViewHelpers

      # Set the current_user on the view being tested.
      def login_as(user)
        view.current_user = user
      end

      module CurrentUser
        attr_accessor :current_user

        def logged_in?
          current_user.present?
        end

        def logged_out?
          !logged_in?
        end
      end

    end
  end
end
