class Comment2ReadModel < ApplicationRecord
  include HasHypermediaLinks

  self.table_name = 'comment2_read_models'
  self.primary_key = 'id'

  scope :for_article, ->(article2_id) { where(article2_id: article2_id) }

  # Hypermedia model mapping
  def hypermedia_model_name
    'Comment2'
  end

  def hypermedia_new_links(current_user)
    super(current_user, 'Comment2')
  end

  def hypermedia_edit_links(current_user)
    super(current_user, 'Comment2')
  end

  # Allowed state transitions for the read model
  def possible_status_events
    case state
    when 'pending'
      %w[approve reject delete]
    when 'approved'
      %w[delete]
    when 'rejected'
      %w[resubmit delete]
    when 'deleted'
      %w[restore]
    else
      []
    end
  end

  # Use Comment2Policy for authorization
  def policy(current_user)
    Comment2Policy.new(current_user, self)
  end
end


