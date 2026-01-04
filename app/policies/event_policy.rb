# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  def index?
    user.id.present? && user.admin?
  end
end
