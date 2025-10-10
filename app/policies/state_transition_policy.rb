class StateTransitionPolicy < ApplicationPolicy
  def index?
    user.admin?
  end
end