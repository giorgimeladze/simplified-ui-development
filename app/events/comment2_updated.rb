class Comment2Updated < BaseEvent
  attr_reader :comment2_id, :text, :user_id
  
  def initialize(comment2_id, text, user_id)
    super()
    @comment2_id = comment2_id
    @text = text
    @user_id = user_id
  end
  
  private
  
  def event_specific_data
    {
      comment2_id: @comment2_id,
      text: @text,
      user_id: @user_id
    }
  end
end
