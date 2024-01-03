
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
  
  # A number of default roles are defined. Their suggested use is stated below.
  # This is just a suggestion and needs to be adapted to the specific application.
  #
  # Superuser: A user with full permissions in a multi-tenant system.
  # Admin: Typical admin role. Highest permission in a single tenant.
  # Manager: Ability to add and remove user within a group of users.
  # Editor: Normal editing permissions.
  # Contributor: Allowed to make changes but with some limitied permissions.
  # Viewer: Read only access.
  # Limited: Any kind of users with limited access, e.g. freemium users.
  #
  # NOTE: only add new roles to the end of the list.
  roles :superuser, :admin, :manager, :editor, :contributor, :viewer, :limited

