# frozen_string_literal: true

class DropArticle2s < ActiveRecord::Migration[7.1]
  def up
    drop_table :article2s
  end

  def down
    create_table :article2s do |t|
      t.string :title
      t.text :content
      t.string :status, default: 'draft'
      t.references :user, null: false, foreign_key: true
      t.text :rejection_feedback

      t.timestamps
    end

    add_index :article2s, [:status]
  end
end
