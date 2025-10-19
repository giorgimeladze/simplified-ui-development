require 'yaml'

module HypermediaConfig
  CONFIG_PATH = Rails.root.join('config', 'hypermedia_actions.yml')
  
  def load_config
    @config ||= YAML.load_file(CONFIG_PATH).deep_symbolize_keys
  end
  
  def actions_for(model_name)
    load_config[model_name.to_sym] || {}
  end
  
  def action_config(model_name, action_name)
    actions_for(model_name)[action_name.to_sym]
  end
  
  def build_link(model_name, action_name, resource_id = nil)
    config = action_config(model_name, action_name)
    return nil unless config
    
    href = config[:link].gsub('#ID', resource_id.to_s) if resource_id
    href ||= config[:link]
    
    {
      rel: config[:rel],
      title: config[:title],
      method: config[:method],
      href: href,
      button_classes: config[:button_classes],
      confirm: config[:confirm]
    }
  end

  def available_actions(model_name)
    actions_for(model_name).keys
  end
  
  def navigation_links(current_user)
    is_signed_in = current_user.present?
    is_admin = current_user&.admin?
    
    navigation_actions.map do |action_name, config|
      next if config[:rel] == 'sign-in' && is_signed_in
      next if config[:rel] == 'sign-out' && !is_signed_in
      next if config[:rel] == 'sign-up' && is_signed_in
      
      # Filter admin-only navigation links
      next if config[:admin_only] && !is_admin
      
      {
        rel: config[:rel],
        title: config[:title],
        method: config[:method],
        href: config[:link],
        button_classes: config[:button_classes]
      }
    end.compact
  end

  private

  def navigation_actions
    load_config[:Navigation] || {}
  end
end
