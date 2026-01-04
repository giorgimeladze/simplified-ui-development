# frozen_string_literal: true

FactoryBot.define do
  factory :article do
    title { Faker::Lorem.word }
    content { Faker::Lorem.sentence }
    status { 'draft' }
    user { create(:user) }
  end
end
