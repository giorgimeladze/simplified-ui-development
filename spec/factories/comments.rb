FactoryBot.define do
  factory :comment do
    article { nil }
    user { nil }
    text { "MyText" }
    status { "MyString" }
  end
end
