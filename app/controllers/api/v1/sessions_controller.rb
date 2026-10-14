# backend/app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < ApplicationController
      def create
        user = User.find_by(email: params[:email])
        if user&.valid_password?(params[:password])
          token = encode_token({ user_id: user.id })
          render json: { user: { id: user.id, email: user.email, name: user.first_name }, token: token }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def show
        # Assumes authenticate_user! sets @current_user via Bearer token
        render json: { user: current_user }
      end

      private

      def encode_token(payload)
        JWT.encode(payload, Rails.application.credentials.secret_key_base)
      end
    end
  end
end