module ArticleLinks
  def show_links(current_user)
    links = []
    links << { name: 'Back to Listings', action: 'GET', href: "/articles" }

    policy = ArticlePolicy.new(current_user, self)
    current_state = self.aasm.current_state

    Article.aasm.events.each do |event|
      byebug
      if self.aasm.may_fire_event?(event.name) && policy.respond_to?("#{event.name}?") && policy.public_send("#{event.name}?")
        links << {
          name: event.name.to_s.humanize,
          action: 'POST',
          href: "/articles/#{self.id}/transition/#{event.name}"
        }
      end
    end

    links
  end

  def new_links
    [
      { name: 'Back to Listings', action: 'GET', href: "/articles" }
    ]
  end

  def index_links(current_user)
    actions = []
    policy = ArticlePolicy.new(current_user, self)

    actions << { name: 'Show', action: 'GET', href: "/articles/#{self.id}" }
    actions << { name: 'Delete', action: 'DELETE', href: "/articles/#{self.id}" } if policy.destroy?

    Article.aasm.events.each do |event|
      if self.aasm.may_fire_event?(event.name) && policy.respond_to?("#{event.name}?") && policy.public_send("#{event.name}?")
        actions << {
          name: event.name.to_s.humanize,
          action: 'POST',
          href: "/articles/#{self.id}/transition/#{event.name}"
        }
      end
    end

    actions
  end

  def self.general_index(current_user)
    links = []

    if ArticlePolicy.new(current_user, Article).new?
      links << { name: 'New', action: 'GET', href: '/articles/new' }
    end

    if current_user
      links << { name: 'Logout', action: 'DELETE', href: '/users/sign_out' }
    else
      links << { name: 'Login', action: 'GET', href: '/users/sign_in' }
    end

    links
  end
end
