# backend/app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def sign_up_params
    params[resource_name] ||= params[:user] || params.dig(:registration, :user)
    super
  end

  def sign_up(_resource_name, _resource)
    # API clients authenticate separately through the JWT login endpoint.
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      token, payload = Warden::JWTAuth::UserEncoder.new.call(
        resource,
        resource_name,
        Warden::JWTAuth::EnvHelper.aud_header(request.env)
      )
      resource.on_jwt_dispatch(token, payload) if resource.respond_to?(:on_jwt_dispatch)
      response.headers[Warden::JWTAuth.config.token_header] = "Bearer #{token}"

      render json: {
        status: { code: 200, message: "Signed up successfully." },
        user: { id: resource.id, email: resource.email },
        token: token
      }, status: :ok
    else
      # Inspect errors directly in terminal logs
      Rails.logger.error("User signup failed: #{resource.errors.full_messages.inspect}")

      render json: {
        status: { code: 422, message: "User could not be created." },
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end