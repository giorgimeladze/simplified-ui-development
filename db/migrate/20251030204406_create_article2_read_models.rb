class CreateArticle2ReadModels < ActiveRecord::Migration[7.1]
  def change
    create_table :article2_read_models, id: :string do |t|
      t.text :title
      t.text :content
      t.integer :author_id
      t.string :state, default: 'draft'
      t.text :rejection_feedback
    end

    add_index :article2_read_models, [:author_id]
    add_index :article2_read_models, [:state]
  end
end
