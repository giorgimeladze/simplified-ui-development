class CommentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.present? && record.user_id == user.id && (record.pending? || record.rejected?)
  end

  def approve?
    user.present? && user.admin?
  end

  def reject?
    user.present? && user.admin?
  end

  def delete?
    user.present? && (record.user_id == user.id || user.admin? || user.editor?)
  end

  def restore?
    user.present? && (user.admin? || user.editor?)
  end
end