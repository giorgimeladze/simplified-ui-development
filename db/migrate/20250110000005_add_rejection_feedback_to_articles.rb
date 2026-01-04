# frozen_string_literal: true

class AddRejectionFeedbackToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :rejection_feedback, :text
  end
end
