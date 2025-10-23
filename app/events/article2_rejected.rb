class Article2Rejected < BaseEvent
  attr_reader :article2_id, :rejection_feedback, :user_id
  
  def initialize(article2_id, rejection_feedback, user_id)
    super()
    @article2_id = article2_id
    @rejection_feedback = rejection_feedback
    @user_id = user_id
  end
  
  private
  
  def event_specific_data
    {
      article2_id: @article2_id,
      rejection_feedback: @rejection_feedback,
      user_id: @user_id
    }
  end
end
