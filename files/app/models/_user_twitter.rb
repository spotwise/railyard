  def has_twitter?
    return tw_uid.present?
  end
  
  def self.find_for_twitter_oauth(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:tw_uid => auth.uid).first unless user
    p auth unless user
    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        password:Devise.friendly_token[0,20]
        )
      session["user_return_to"] = "/users/edit"
    end
  
    if User.is_uid_taken?(user, :tw_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end
  
    user.update(
          tw_uid:auth.uid,
          tw_name:auth.info.name,
          tw_nickname:auth.info.nickname,
          tw_location:auth.info.location,
          tw_image:auth.info.image,
          tw_description:auth.info.description,
          tw_friends:auth.extra.raw_info.friends_count,
          tw_followers:auth.extra.raw_info.followers_count,
          tw_statuses:auth.extra.raw_info.statuses_count,
          tw_listed:auth.extra.raw_info.listed_count
          )
    user
  end
