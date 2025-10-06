class ArticlePolicy < ApplicationPolicy

  def articles_for_review?
    user.admin?
  end

  def deleted_articles?
    user.editor? || user.admin?
  end

  def show?
    true
  end

  def new?
    user.editor? || user.admin?
  end

  def submit?
    user.editor? || user.admin?
  end

  def approve_private?
    user.admin? || user.editor?
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

  def destroy?
    user.admin? || user.editor?
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
