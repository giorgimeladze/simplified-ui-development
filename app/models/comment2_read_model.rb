class Comment2ReadModel < ApplicationRecord
  self.table_name = 'comment2_read_models'
  self.primary_key = 'id'

  scope :for_article, ->(article2_id) { where(article2_id: article2_id) }
end


