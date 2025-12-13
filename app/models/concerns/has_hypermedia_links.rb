module HasHypermediaLinks
  extend ActiveSupport::Concern
  include HypermediaConfig
  
  def hypermedia_model_name
    self.class.name
  end
  
  def hypermedia_show_links(current_user)
    links = []
    links << build_link(hypermedia_model_name, :edit, current_user) if policy(current_user).update?
    
    add_transition_links(links, current_user)
    
    links.compact
  end
  
  def hypermedia_index_links(current_user)
    links = []
    links << build_link(hypermedia_model_name, :show, current_user)
    
    add_transition_links(links, current_user)
    links.compact
  end

  def hypermedia_new_links(current_user, model_class_name='Article')
    link = build_link(hypermedia_model_name, :index, current_user)
    link[:title] = "Back to #{model_class_name.pluralize}"
    [link]
  end
  
  def hypermedia_edit_links(current_user, model_class_name='Article')
    link = build_link(hypermedia_model_name, :show, current_user)
    link[:title] = "Back to #{model_class_name}"
    [link]
  end
  
  def self.hypermedia_navigation_links(current_user)
    temp_instance = Object.new
    temp_instance.extend(HypermediaConfig)
    temp_instance.navigation_links(current_user)
  end

  def self.hypermedia_general_index(current_user, model_class_name)
    temp_instance = Object.new
    temp_instance.extend(HypermediaConfig)
    [temp_instance.build_link(model_class_name, :new, current_user)]
  end

  def self.hypermedia_general_show(current_user, model_class_name, additional_params = {})
    temp_instance = Object.new
    temp_instance.extend(HypermediaConfig)
    temp_instance.define_singleton_method(:id) { additional_params[:id] } if additional_params[:id]
    [temp_instance.build_link(model_class_name, :index, current_user)]
  end
  
  private
  
  def add_transition_links(links, current_user)
    model_policy = policy(current_user)
    
    possible_status_events.each do |event|
      policy_method = "#{event.to_s}?"
      next unless model_policy.respond_to?(policy_method)
      next unless model_policy.public_send(policy_method)      
      
      links << build_link(hypermedia_model_name, event.to_s, current_user)
    end
  end
  
  def policy(current_user)
    policy_class = "#{self.class.name}Policy".constantize
    policy_class.new(current_user, self)
  end
end
