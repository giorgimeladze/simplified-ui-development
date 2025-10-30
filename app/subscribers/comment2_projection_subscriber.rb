class Comment2ProjectionSubscriber
  def call(event)
    ::Comment2Projection.apply(event)
  end
end


