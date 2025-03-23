module LinksRenderer
  include ActionView::Helpers::UrlHelper

  DEFAULT_STYLES = {
    'GET' => { class: 'btn btn-outline-primary btn-sm mx-1', label: nil },
    'DELETE' => { class: 'btn btn-outline-danger btn-sm mx-1', label: nil, confirm: 'Are you sure?' },
    'POST' => { class: 'btn btn-outline-success btn-sm mx-1', label: nil }
  }.freeze

  def render_links(links, custom_styles = {})
    links.map do |link|
      action = link[:action]
      style = DEFAULT_STYLES[action].merge(custom_styles[action] || {})

      label = style[:label] || link[:name].capitalize
      classes = style[:class]

      case action
      when 'GET'
        link_to label, link[:href], class: classes
      when 'DELETE'
        button_to label, link[:href], method: :delete, class: classes, data: { confirm: style[:confirm] }
      when 'POST'
        button_to label, link[:href], method: :post, class: classes
      end
    end.join(' ').html_safe
  end
end
