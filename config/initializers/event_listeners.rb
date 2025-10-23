Rails.application.config.to_prepare do
  Article2Listeners.subscribe_to(EventBus)
  Comment2Listeners.subscribe_to(EventBus)
end
