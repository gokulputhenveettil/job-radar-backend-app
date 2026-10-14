require "test_helper"

class UserJobStatusTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @user = User.create!(email: "owner@example.com", password: "password123")
    @other_user = User.create!(email: "other@example.com", password: "password123")
    @job = TrackedJob.create!(
      linkedin_job_id: "12345678",
      title: "Backend Engineer",
      url: "https://example.com/jobs/12345678"
    )
  end

  test "saved and applied status is scoped to the authenticated user" do
    patch "/api/v1/jobs/#{@job.id}/toggle_saved", headers: auth_headers(@user)
    assert_response :ok
    assert response.parsed_body["saved"]

    patch "/api/v1/jobs/#{@job.id}/toggle_applied", headers: auth_headers(@other_user)
    assert_response :ok
    assert response.parsed_body["applied"]
    assert_not response.parsed_body["saved"]

    get "/api/v1/jobs", headers: auth_headers(@user)
    assert_response :ok
    user_job = response.parsed_body.find { |job| job["id"] == @job.id }
    assert user_job["saved"]
    assert_not user_job["applied"]
  end

  test "dismissal only hides the job for the authenticated user" do
    patch "/api/v1/jobs/#{@job.id}/dismiss", headers: auth_headers(@user)
    assert_response :ok

    get "/api/v1/jobs", headers: auth_headers(@user)
    assert_not_includes response.parsed_body.map { |job| job["id"] }, @job.id

    get "/api/v1/jobs", headers: auth_headers(@other_user)
    assert_response :ok
    assert_includes response.parsed_body.map { |job| job["id"] }, @job.id
  end

  test "public index returns shared jobs without user-specific status" do
    patch "/api/v1/jobs/#{@job.id}/toggle_saved", headers: auth_headers(@user)

    get "/api/v1/jobs"

    assert_response :ok
    job = response.parsed_body.find { |record| record["id"] == @job.id }
    assert job
    assert_not job["saved"]
    assert_not job["applied"]
    assert_not job["dismissed"]
  end

  private

  def auth_headers(user)
    token, = Warden::JWTAuth::UserEncoder.new.call(user, :api_v1_user, nil)
    { "Authorization" => "Bearer #{token}" }
  end
end
