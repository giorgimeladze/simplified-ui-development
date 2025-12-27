# frozen_string_literal: true

module AuthenticationHelper
  def sign_in_as(user)
    password = user.respond_to?(:password) && user.password.present? ? user.password : 'password123'
    post user_session_path, params: {
      user: {
        email: user.email,
        password: password
      }
    }
    follow_redirect! if response.redirect?
    user
  end

  def sign_in_user(role: :admin, email: nil, password: nil)
    user = create(:user, role: role, email: email || Faker::Internet.email)
    user.password = password || 'password123'
    user.save!
    sign_in_as(user)
    user
  end

  def sign_out_user
    delete destroy_user_session_path
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :request
end

