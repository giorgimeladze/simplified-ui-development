class Article2Updated < BaseEvent
  attr_reader :article2_id, :title, :content, :user_id
  
  def initialize(article2_id, title, content, user_id, metadata = {})
    super(metadata)
    @article2_id = article2_id
    @title = title
    @content = content
    @user_id = user_id
  end
  
  private
  
  def event_specific_data
    {
      article2_id: @article2_id,
      title: @title,
      content: @content,
      user_id: @user_id
    }
  end
end
