class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has()
  allow_browser versions: :modern

  # Для production в Docker отключаем CSRF токены
  if Rails.env.production?
    skip_before_action :verify_authenticity_token
  else
    protect_from_forgery with: :exception
  end
end
