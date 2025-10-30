class Article2ReadModel < ApplicationRecord
  self.table_name = 'article2_read_models'
  self.primary_key = 'id'

  scope :by_author, ->(user_id) { where(author_id: user_id) }
end


