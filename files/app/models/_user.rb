
  def email_required?
    super && provider.blank?
  end
  
  def self.is_uid_taken?(user, column, uid)
    u = User.where(column => uid).first
    return true if u and u.id != user.id
    return false
  end
  
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end
  
  # Role model
  include RoleModel
  
  # The attribute to store roles in.
  roles_attribute :roles_mask
  
  # Valid roles. (NOTE: only add new roles to the end of the list)
  roles :superuser, :admin, :manager, :editor, :reader, :trial, :freemium

