module ApplicationHelper
  include LinksRenderer

  def status_badge(status, model_type = 'article')
    color_class = status_color_class(status, model_type)
    content_tag(:span, status.titleize, class: "badge #{color_class} ms-2")
  end

  def state_badge(state, model_type = 'article')
    color_class = status_color_class(state, model_type)
    content_tag(:span, state.titleize, class: "badge #{color_class} ms-2")
  end

  private

  def status_color_class(status, model_type)
    case model_type
    when 'article', 'article2'
      article_status_color(status)
    when 'comment', 'comment2'
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

  def model_link(class_name, action, current_user=nil)
    class_name = "#{class_name.camelize}ReadModel"
    class_object = class_name.constantize.new
    class_object.build_link(class_object.hypermedia_model_name, action, current_user).values_at(:title, :button_classes)
  end
end
