# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { Faker::Internet.username }
    password { SecureRandom.hex(8) }
    role { 'admin' }
  end
end
