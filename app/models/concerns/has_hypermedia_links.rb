module HasHypermediaLinks
  extend ActiveSupport::Concern
  include HypermediaConfig
  
  def hypermedia_model_name
    self.class.name
  end
  
  def hypermedia_show_links(current_user)
    links = []
    links << build_link(hypermedia_model_name, :index)
    
    add_fsm_transition_links(links, current_user)
    
    links.compact
  end
  
  def hypermedia_index_links(current_user)
    links = []
    model_policy = policy(current_user)
    
    links << build_link(hypermedia_model_name, :show, id)
    links << build_link(hypermedia_model_name, :destroy, id) if model_policy.destroy?
    
    add_fsm_transition_links(links, current_user)
    links.compact
  end

  def hypermedia_new_links
    link = build_link(hypermedia_model_name, :index)
    link[:title] = 'Back to Articles'
    [link]
  end
  
  def self.hypermedia_navigation_links(current_user)
    temp_instance = Object.new
    temp_instance.extend(HypermediaConfig)
    temp_instance.navigation_links(current_user)
  end

  def self.hypermedia_general_index(current_user)
    temp_instance = Object.new
    temp_instance.extend(HypermediaConfig)
    [temp_instance.build_link('Article', :new)]
  end
  
  private
  
  def add_fsm_transition_links(links, current_user)
    return unless respond_to?(:aasm)
    
    transition_actions = self.class.aasm.events
    model_policy = policy(current_user)
    
    transition_actions.each do |event|
      next unless aasm.may_fire_event?(event.name)
      
      policy_method = "#{event.name}?"
      next unless model_policy.respond_to?(policy_method)
      next unless model_policy.public_send(policy_method)
      
      links << build_link(hypermedia_model_name, event.name, id)
    end
  end
  
  def policy(current_user)
    policy_class = "#{self.class.name}Policy".constantize
    policy_class.new(current_user, self)
  end
end
