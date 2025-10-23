class Comment2Rejected < BaseEvent
  attr_reader :comment2_id, :rejection_feedback, :user_id
  
  def initialize(comment2_id, rejection_feedback, user_id, metadata = {})
    super(metadata)
    @comment2_id = comment2_id
    @rejection_feedback = rejection_feedback
    @user_id = user_id
  end
  
  private
  
  def event_specific_data
    {
      comment2_id: @comment2_id,
      rejection_feedback: @rejection_feedback,
      user_id: @user_id
    }
  end
end
