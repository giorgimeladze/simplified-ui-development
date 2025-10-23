Rails.application.config.to_prepare do
  # Register event listeners with the event bus
  Article2Listeners.subscribe(EventBus)
  Comment2Listeners.subscribe(EventBus)
end
