module LinksRenderer
  include ActionView::Helpers::UrlHelper

  # Fallback styles if not specified in YAML config
  DEFAULT_STYLES = {
    'GET' => { class: 'btn btn-outline-primary btn-sm mx-1', label: nil },
    'DELETE' => { class: 'btn btn-outline-danger btn-sm mx-1', label: nil, confirm: 'Are you sure?' },
    'POST' => { class: 'btn btn-outline-success btn-sm mx-1', label: nil }
  }.freeze

  def render_links(links, custom_styles = {})
    links.map do |link|
      method = (link[:method] || 'GET').to_s.upcase
      
      # Use button_classes from YAML config if available, otherwise fall back to default styles
      classes = link[:button_classes] || DEFAULT_STYLES[method][:class]
      
      # Apply custom styles if provided
      if custom_styles[method]
        classes = custom_styles[method][:class] if custom_styles[method][:class]
      end

      label = link[:title] || link[:rel].to_s.humanize
      confirm_message = link[:confirm] || DEFAULT_STYLES[method][:confirm]

      case method
      when 'GET'
        link_to label, link[:href], class: classes
      when 'DELETE'
        button_to label, link[:href], method: :delete, class: classes, data: { confirm: confirm_message }
      when 'POST'
        button_to label, link[:href], method: :post, class: classes
      else
        # Fallback to POST for unknown methods
        button_to label, link[:href], method: :post, class: classes
      end
    end.join(' ').html_safe
  end
end
