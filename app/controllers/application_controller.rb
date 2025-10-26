class ApplicationController < ActionController::Base
  include Pundit
  include LinksRenderer

  # Skip CSRF protection for JSON API requests
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_header_links
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end

  private

  def set_header_links
    @header_links = HasHypermediaLinks.hypermedia_navigation_links(current_user)
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
