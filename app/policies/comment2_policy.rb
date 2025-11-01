class Comment2Policy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def pending_comment2s?
    user.admin?
  end

  def create?
    user.present?
  end

  def update?
    user.present? && record.author_id == user.id && (record.state == 'pending' || record.state == 'rejected')
  end

  def approve?
    user.present? && user.admin?
  end

  def reject?
    user.present? && user.admin?
  end

  def delete?
    user.present? && (record.author_id == user.id || user.admin? || user.editor?)
  end

  def restore?
    user.present? && (user.admin? || user.editor?)
  end
end
