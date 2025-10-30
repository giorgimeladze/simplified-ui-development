class CreateComment2ReadModels < ActiveRecord::Migration[7.1]
  def change
    create_table :comment2_read_models, id: :string do |t|
      t.text :text
      t.string :article2_id
      t.integer :author_id
      t.string :state, default: 'pending'
      t.text :rejection_feedback
    end

    add_index :comment2_read_models, [:article2_id]
    add_index :comment2_read_models, [:author_id]
    add_index :comment2_read_models, [:state]
  end
end
