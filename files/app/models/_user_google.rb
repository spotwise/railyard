  def has_google?
    return go_uid.present?
  end
  
  def self.find_for_google_oauth2(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:go_uid => auth.uid).first unless user
  
    p auth unless user

    # Prevent account creation via social login
    unless Rails.application.config.allow_social_account_creation || signed_in_resource || user
      # This means that the user is not logged in and there was no matching User object
      session["flash_error"] = "A local account is required in order to log on using Google."
      return nil
    end

    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        email:auth.info.email,
        password:Devise.friendly_token[0,20]
        )
      session["user_return_to"] = "/users/edit"
    end
  
    if User.is_uid_taken?(user, :go_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end
  
    user.update(
        go_uid:auth.uid,
        go_email:auth.info.email,
        go_first_name:auth.info.first_name,
        go_last_name:auth.info.last_name,
        go_name:auth.info.name,
        go_image:auth.info.image
        )
    user
  end
