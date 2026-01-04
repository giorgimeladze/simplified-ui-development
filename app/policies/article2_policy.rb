# frozen_string_literal: true

class Article2Policy < ApplicationPolicy
  def article2s_for_review?
    user.admin?
  end

  def deleted_article2s?
    user.editor? || user.admin?
  end

  def show?
    true
  end

  def new?
    user.editor? || user.admin?
  end

  def create?
    user.editor? || user.admin?
  end

  def submit?
    (user.editor? && record.author_id == user.id) || user.admin?
  end

  def approve_private?
    user.admin?
  end

  def reject?
    user.admin?
  end

  def resubmit?
    (user.editor? && record.author_id == user.id) || user.admin?
  end

  def archive?
    (user.editor? && record.author_id == user.id) || user.admin?
  end

  def publish?
    user.admin?
  end

  def make_visible?
    (user.editor? && record.author_id == user.id) || user.admin?
  end

  def make_invisible?
    (user.editor? && record.author_id == user.id) || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
