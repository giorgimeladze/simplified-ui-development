class CreateCustomTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.json :template_data, null: false, default: {}
      t.timestamps
    end

    add_index :custom_templates, :user_id, unique: true
    User.all.each do |user|
      CustomTemplate.for_user(user)
    end
  end
end
