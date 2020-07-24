class Ability
  include CanCan::Ability

  def initialize(user)
    # TODO: Modify permissions based on role
  	can :manage, :all
  end
end