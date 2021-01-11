  def has_office365?
    return o3_uid.present?
  end
  
  def self.find_for_office365_oauth(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:o3_uid => auth.uid).first unless user
  
    p auth unless user
    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        email:auth.info.email,
        password:Devise.friendly_token[0,20]
        )
      session["user_return_to"] = "/users/edit"
    end
  
    if User.is_uid_taken?(user, :o3_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end
  
    user.update(
        o3_uid:auth.uid,
        o3_email:auth.info.email,
        o3_name:auth.info.name,
        )
    user
  end
