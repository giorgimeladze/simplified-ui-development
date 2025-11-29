class EventPolicy < ApplicationPolicy
  def index?
    user.id.present? && (user.admin?)
  end
end
