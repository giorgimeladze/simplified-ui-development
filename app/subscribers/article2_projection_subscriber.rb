class Article2ProjectionSubscriber
  def call(event)
    ::Article2Projection.apply(event)
  end
end


