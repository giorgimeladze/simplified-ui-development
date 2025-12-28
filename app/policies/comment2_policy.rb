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
    user.id.present?
  end

  def update?
    user.id.present? && record.author_id == user.id && (record.state == 'pending' || record.state == 'rejected')
  end

  def approve?
    user.id.present? && user.admin?
  end

  def reject?
    user.id.present? && user.admin?
  end

  def delete?
    user.id.present? && ((record.author_id == user.id && user.editor?) || user.admin?)
  end

  def restore?
    user.id.present? && ((record.author_id == user.id && user.editor?) || user.admin?)
end
end
