class CommentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.id.present?
  end

  def update?
    user.id.present? && record.user_id == user.id && (record.pending? || record.rejected?)
  end

  def approve?
    user.id.present? && user.admin?
  end

  def reject?
    user.id.present? && user.admin?
  end

  def delete?
    user.id.present? && (record.user_id == user.id || user.admin? || user.editor?)
  end

  def restore?
    user.id.present? && (user.admin? || user.editor?)
  end
end