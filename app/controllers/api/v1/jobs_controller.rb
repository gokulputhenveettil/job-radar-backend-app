# backend/app/controllers/api/v1/jobs_controller.rb
module Api
  module V1
    class JobsController < ApplicationController
      before_action :authenticate_api_v1_user!, only: [ :toggle_saved, :toggle_applied, :dismiss ]
      before_action :set_job, only: [ :toggle_saved, :toggle_applied, :dismiss, :generate_cover_letter ]

      # GET /api/v1/jobs
      def index
        user = current_api_v1_user
        jobs = TrackedJob.recent

        if params[:location].present?
          query = "%#{params[:location].strip}%"
          jobs = jobs.where("location ILIKE ?", query)
        end

        if user
          jobs = jobs.where.not(
            id: user.user_tracked_jobs.where(dismissed: true).select(:tracked_job_id)
          ).limit(100)
        end
        jobs = jobs.limit(100)
        job_records = jobs.to_a
        statuses = user ? user.user_tracked_jobs
          .where(tracked_job_id: job_records.map(&:id))
          .index_by(&:tracked_job_id) : {}

        render json: job_records.map { |job| job_json(job, statuses[job.id]) }
      end

      # POST /api/v1/jobs/poll
      def poll
        keywords = params[:keywords].presence || "Ruby on Rails"
        location = params[:location].presence || "Remote"
        email = params[:email].presence || "you@example.com"

        MonitorLinkedinJobsJob.perform_later(
          recipient_email: email,
          keywords: keywords,
          location: location
        )

        render json: { message: "Scrape initiated for '#{keywords}' in '#{location}'." }, status: :accepted
      end

      # PATCH /api/v1/jobs/:id/toggle_saved
      def toggle_saved
        status = user_status
        status.update!(saved: !status.saved)
        render json: job_json(@job, status)
      end

      # PATCH /api/v1/jobs/:id/toggle_applied
      def toggle_applied
        status = user_status
        status.update!(applied: !status.applied)
        render json: job_json(@job, status)
      end

      # PATCH /api/v1/jobs/:id/dismiss
      def dismiss
        user_status.update!(dismissed: true)
        render json: { success: true, id: @job.id }
      end

      def generate_cover_letter
        format_type = params[:format_type].presence || "inmail"

        GenerateCoverLetterJob.perform_later(@job.id, format_type)

        render json: { status: "queued", job_id: @job.id, format_type: format_type }, status: :accepted
      end

      private

      def user_status
        @user_status ||= current_api_v1_user.user_tracked_jobs.find_or_initialize_by(tracked_job: @job)
      end

      def job_json(job, status)
        job.as_json.merge(
          "saved" => status&.saved || false,
          "applied" => status&.applied || false,
          "dismissed" => status&.dismissed || false
        )
      end

      def set_job
        @job = TrackedJob.find(params[:id])
      end
    end
  end
end
