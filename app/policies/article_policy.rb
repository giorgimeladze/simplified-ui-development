class ArticlePolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    true
  end

  def submit?
    user.editor? || user.admin?
  end

  def approve?
    user.admin?
  end

  def reject?
    user.admin?
  end

  def resubmit?
    user.editor? || user.admin?
  end

  def archive?
    user.editor? || user.admin?
  end

  def publish?
    user.admin?
  end

  def make_visible?
    user.editor? || user.admin?
  end

  def make_invisible?
    user.editor? || user.admin?
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
