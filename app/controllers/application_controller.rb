class ApplicationController < ActionController::Base
  include Pundit
  include LinksRenderer

  # Skip CSRF protection for JSON API requests
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  before_action :authenticate_user!, unless: -> { devise_controller? }
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_header_links
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

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
    respond_to do |format|
      format.json { render json: { error: "forbidden" }, status: :forbidden }
      format.html do
        flash[:alert] = "You are not authorized to perform this action."
        redirect_to(request.referrer || root_path)
      end
    end
  end

  def record_not_found
    respond_to do |format|
      format.json { render json: { error: 'not_found' }, status: :not_found }
      format.html { raise ActiveRecord::RecordNotFound }
    end
  end
end
