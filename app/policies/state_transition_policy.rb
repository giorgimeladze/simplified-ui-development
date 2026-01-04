# frozen_string_literal: true

class StateTransitionPolicy < ApplicationPolicy
  def index?
    user.admin?
  end
end
