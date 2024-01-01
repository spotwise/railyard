
    # Change layout for edit page
    config.to_prepare do
      #Devise::RegistrationsController.layout proc{ |controller| action_name == 'edit' ? "application" : "devise" }
    end

    # Configure whether is is possible to create accounts via social platform authentication.
    # If this configuration option is false, it is only possible to log on using OAuth after
    # first having logged on using a local account and then associating that account with
    # one or more social platforms.
    #
    # Note that /users/sign_up is still accessible so it is trivial for users to create
    # their own account. Disable this route if required by the application.
    config.allow_social_account_creation = true
