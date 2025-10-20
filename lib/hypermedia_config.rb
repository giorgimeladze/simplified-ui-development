require 'yaml'

module HypermediaConfig
  CONFIG_PATH = Rails.root.join('config', 'hypermedia_actions.yml')

  def build_link(model_name, action_name, current_user = nil)
    config = action_config(model_name, action_name)
    return nil unless config

    href = config[:link].gsub('#ID', id.to_s) if self.respond_to?(:id)
    href ||= config[:link]
    
    action_string_name = action_name.to_s
    # Get custom template data for the user
    customization = get_customization(model_name, action_string_name, current_user)
    
    {
      rel: config[:rel],
      title: customization['title'] || action_string_name.humanize,
      method: config[:method],
      href: href,
      button_classes: customization['button_classes'] || 'btn btn-outline-primary btn-sm mx-1',
      confirm: config[:confirm]
    }
  end
  
  def navigation_links(current_user)
    is_signed_in = current_user.present?
    is_admin = current_user&.admin?
    
    navigation_actions.map do |action_name, config|
      next if config[:rel] == 'sign-in' && is_signed_in
      next if config[:rel] == 'sign-out' && !is_signed_in
      next if config[:rel] == 'sign-up' && is_signed_in
      next if config[:rel] == 'custom_template' && !is_signed_in
      
      # Filter admin-only navigation links
      next if config[:admin_only] && !is_admin
      
      action_string_name = action_name.to_s
      # Get custom template data for navigation
      customization = get_customization('Navigation', action_string_name, current_user)
      
      {
        rel: config[:rel],
        title: customization['title'] || action_string_name.humanize,
        method: config[:method],
        href: config[:link],
        button_classes: customization['button_classes'] || 'btn btn-outline-primary btn-sm mx-1'
      }
    end.compact
  end

  private

  def get_customization(model_name, action_name, current_user)
    return {} unless current_user
    
    template = CustomTemplate.for_user(current_user)
    template.get_customization(model_name, action_name)
  end

  def navigation_actions
    load_config[:Navigation] || {}
  end

  def action_config(model_name, action_name)
    actions_for(model_name)[action_name]
  end
    
  def actions_for(model_name)
    load_config[model_name.to_sym] || {}
  end

  def load_config
    @config ||= YAML.load_file(CONFIG_PATH).deep_symbolize_keys
  end
end
