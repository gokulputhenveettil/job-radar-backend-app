require "test_helper"

class UserRegistrationTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "signs up with user-scoped parameters" do
    assert_difference("User.count") do
      post "/api/v1/auth/signup",
        params: { user: { name: "Gokul", email: "gokul@example.com", password: "password123" } },
        as: :json
    end

    assert_response :ok
    assert_registration_token
  end

  test "signs up with registration-wrapped user parameters" do
    assert_difference("User.count") do
      post "/api/v1/auth/signup",
        params: { registration: { user: { name: "Gokul", email: "wrapped@example.com", password: "password123" } } },
        as: :json
    end

    assert_response :ok
    assert_registration_token
  end

  private

  def assert_registration_token
    token = response.parsed_body.dig("token")

    assert token.present?
    assert_equal "Bearer #{token}", response.headers["Authorization"]

    payload, = JWT.decode(token, Warden::JWTAuth.config.secret, true, algorithm: Warden::JWTAuth.config.algorithm)
    assert_equal response.parsed_body.dig("user", "id").to_s, payload["sub"]
  end
end
