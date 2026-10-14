require "test_helper"

class JobAlertMailerTest < ActionMailer::TestCase
  test "new_jobs_email" do
    mail = JobAlertMailer.new_jobs_email
    assert_equal "New jobs email", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
