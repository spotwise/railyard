  def has_twitter?
    return twitter_uid.present?
  end
  
  def self.find_for_twitter_oauth(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:twitter_uid => auth.uid).first unless user
    p auth unless user
    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        password:Devise.friendly_token[0,20]
        )
      session["user_return_to"] = "/users/edit"
    end
  
    if User.is_uid_taken?(user, :twitter_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end
  
    user.update(
          twitter_uid:auth.uid,
          twitter_name:auth.info.name,
          twitter_nickname:auth.info.nickname,
          twitter_location:auth.info.location,
          twitter_image:auth.info.image,
          twitter_description:auth.info.description,
          twitter_friends:auth.extra.raw_info.friends_count,
          twitter_followers:auth.extra.raw_info.followers_count,
          twitter_statuses:auth.extra.raw_info.statuses_count,
          twitter_listed:auth.extra.raw_info.listed_count
          )
    user
  end
