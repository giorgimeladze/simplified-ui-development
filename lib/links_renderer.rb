module LinksRenderer
  include ActionView::Helpers::UrlHelper

  def render_links(links)
    links.map do |link|
      case link[:action]
      when 'GET'
        link_to link[:name].capitalize, link[:href], class: 'btn btn-outline-primary btn-sm mx-1'
      when 'DELETE'
        button_to link[:name].capitalize, link[:href], method: :delete, class: 'btn btn-outline-danger btn-sm mx-1', data: { confirm: 'Are you sure?' }
      when 'POST'
        button_to link[:name].capitalize, link[:href], method: :post, class: 'btn btn-outline-success btn-sm mx-1'
      end
    end.join(' ').html_safe
  end
end
