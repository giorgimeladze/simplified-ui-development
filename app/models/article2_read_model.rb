# frozen_string_literal: true

class Article2ReadModel < ApplicationRecord
  include HasHypermediaLinks

  self.table_name = 'article2_read_models'
  self.primary_key = 'id'

  has_many :comment2s,
           class_name: "Comment2ReadModel",
           foreign_key: :article2_id,
           primary_key: :id,
           inverse_of: :article2

  # Override model name for URL generation
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, 'Article2')
    end
  end

  scope :by_author, ->(user_id) { where(author_id: user_id) }

  # Hypermedia model mapping
  def hypermedia_model_name
    'Article2'
  end

  def hypermedia_new_links(current_user)
    super(current_user, 'Article2')
  end

  def hypermedia_edit_links(current_user)
    super(current_user, 'Article2')
  end

  # Allowed state transitions for the read model
  def possible_status_events
    case state
    when 'draft'
      %w[submit]
    when 'review'
      %w[reject approve_private publish]
    when 'rejected'
      %w[resubmit archive]
    when 'privated'
      %w[make_visible archive]
    when 'published'
      %w[make_invisible archive]
    else
      []
    end
  end

  # Use Article2Policy for authorization
  def policy(current_user)
    Article2Policy.new(current_user, self)
  end

  def comments
    comment2s
  end
end
