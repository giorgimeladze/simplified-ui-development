# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_10_09_204943) do
  create_table "article2s", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "status", default: "draft"
    t.integer "user_id", null: false
    t.text "rejection_feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_article2s_on_status"
    t.index ["user_id"], name: "index_article2s_on_user_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "status"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "rejection_feedback"
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "comment2s", force: :cascade do |t|
    t.integer "article2_id", null: false
    t.integer "user_id", null: false
    t.text "text", null: false
    t.string "status", default: "pending", null: false
    t.text "rejection_feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article2_id"], name: "index_comment2s_on_article2_id"
    t.index ["status"], name: "index_comment2s_on_status"
    t.index ["user_id"], name: "index_comment2s_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "user_id", null: false
    t.text "text", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "rejection_feedback"
    t.index ["article_id"], name: "index_comments_on_article_id"
    t.index ["status"], name: "index_comments_on_status"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "custom_templates", force: :cascade do |t|
    t.integer "user_id", null: false
    t.json "template_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_custom_templates_on_user_id"
  end

  create_table "state_transitions", force: :cascade do |t|
    t.string "transitionable_type", null: false
    t.integer "transitionable_id", null: false
    t.string "from_state", null: false
    t.string "to_state", null: false
    t.string "event", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transitionable_type", "transitionable_id"], name: "index_state_transitions_on_transitionable"
    t.index ["user_id"], name: "index_state_transitions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "username", null: false
    t.integer "role", default: 0, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "article2s", "users"
  add_foreign_key "articles", "users"
  add_foreign_key "comment2s", "article2s"
  add_foreign_key "comment2s", "users"
  add_foreign_key "comments", "articles"
  add_foreign_key "comments", "users"
  add_foreign_key "custom_templates", "users"
  add_foreign_key "state_transitions", "users"
end
