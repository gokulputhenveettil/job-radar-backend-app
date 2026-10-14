# Preview all emails at http://localhost:3000/rails/mailers/job_alert_mailer
class JobAlertMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/job_alert_mailer/new_jobs_email
  def new_jobs_email
    JobAlertMailer.new_jobs_email
  end
end
