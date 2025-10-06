module ArticleLinks
  def show_links(current_user)
    links = []
    links << { rel: 'collection', title: 'Back to Listings', method: 'GET', href: "/articles" }

    policy = ArticlePolicy.new(current_user, self)
    current_state = self.aasm.current_state

    Article.aasm.events.each do |event|
      if self.aasm.may_fire_event?(event.name) && policy.respond_to?("#{event.name}?") && policy.public_send("#{event.name}?")
        links << {
          rel: "transition:#{event.name}",
          title: event.name.to_s.humanize,
          method: 'POST',
          href: "/articles/#{self.id}/#{event.name}"
        }
      end
    end

    links
  end

  def new_links
    [
      { rel: 'collection', title: 'Back to Listings', method: 'GET', href: "/articles" }
    ]
  end

  def index_links(current_user)
    actions = []
    policy = ArticlePolicy.new(current_user, self)

    actions << { rel: 'self', title: 'Show', method: 'GET', href: "/articles/#{self.id}" }
    actions << { rel: 'delete', title: 'Delete', method: 'DELETE', href: "/articles/#{self.id}" }

    Article.aasm.events.each do |event|
      if self.aasm.may_fire_event?(event.name) && policy.respond_to?("#{event.name}?") && policy.public_send("#{event.name}?")
        actions << {
          rel: "transition:#{event.name}",
          title: event.name.to_s.humanize,
          method: 'POST',
          href: "/articles/#{self.id}/#{event.name}"
        }
      end
    end

    actions
  end

  def self.general_index(current_user)
    links = []

    links << { rel: 'new', title: 'New', method: 'GET', href: '/articles/new' }

    links
  end
end
