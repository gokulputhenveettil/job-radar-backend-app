# backend/app/mailers/job_alert_mailer.rb
class JobAlertMailer < ApplicationMailer
  default from: "alerts@example.com"

  def new_jobs_email(recipient_email, jobs)
    @jobs = jobs
    mail(to: recipient_email, subject: "🚨 Found #{@jobs.size} New LinkedIn Posting#{@jobs.size > 1 ? 's' : ''}")
  end
end