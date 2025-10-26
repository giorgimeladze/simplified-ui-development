class AddRejectionFeedbackToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :rejection_feedback, :text
  end
end
