class Comment2Approved < BaseEvent
  attr_reader :comment2_id, :user_id
  
  def initialize(comment2_id, user_id)
    super()
    @comment2_id = comment2_id
    @user_id = user_id
  end
  
  private
  
  def event_specific_data
    {
      comment2_id: @comment2_id,
      user_id: @user_id
    }
  end
end
