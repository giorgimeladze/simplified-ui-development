# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    article { create(:article) }
    user { create(:user) }
    text { Faker::Lorem.sentence }
    status { 'pending' }
  end
end
