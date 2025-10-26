class CreateArticle2s < ActiveRecord::Migration[7.1]
  def change
    create_table :article2s do |t|
      t.string :title
      t.text :content
      t.string :status, default: 'draft'
      t.integer :user_id, null: false
      t.text :rejection_feedback
      
      t.timestamps
    end
    
    add_index :article2s, [:user_id]
    add_index :article2s, [:status]
    add_foreign_key :article2s, :users
  end
end
