module ApplicationHelper
  include LinksRenderer

  def status_badge(status, model_type = 'article')
    color_class = status_color_class(status, model_type)
    content_tag(:span, status.titleize, class: "badge #{color_class} ms-2")
  end

  private

  def status_color_class(status, model_type)
    case model_type
    when 'article'
      article_status_color(status)
    when 'comment'
      comment_status_color(status)
    end
  end

  def article_status_color(status)
    {
      'draft' => 'bg-secondary',
      'review' => 'bg-warning text-dark',
      'rejected' => 'bg-danger',
      'published' => 'bg-success',
      'privated' => 'bg-info',
      'archived' => 'bg-dark'
    }[status] || 'bg-secondary'
  end

  def comment_status_color(status)
    {
      'pending' => 'bg-warning text-dark',
      'approved' => 'bg-success',
      'deleted' => 'bg-danger'
    }[status] || 'bg-secondary'
  end

  def model_link(class_name, model, action, current_user=nil)
    class_name.constantize.find(model[:id]).build_link(class_name, action, current_user).values_at(:title, :button_classes)
  end
end
