# backend/app/controllers/api/v1/jobs_controller.rb
module Api
  module V1
    class JobsController < ApplicationController
      before_action :set_job, only: [:toggle_saved, :toggle_applied, :dismiss]

      # GET /api/v1/jobs
      def index
        @jobs = TrackedJob.recent

        if params[:location].present?
          query = "%#{params[:location].strip}%"
        @jobs = @jobs.where("location ILIKE ?", query)
        end
        
        render json: @jobs.limit(100)
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
        @job.update!(saved: !@job.saved)
        render json: @job
      end

      # PATCH /api/v1/jobs/:id/toggle_applied
      def toggle_applied
        @job.update!(applied: !@job.applied)
        render json: @job
      end

      # PATCH /api/v1/jobs/:id/dismiss
      def dismiss
        @job.update!(dismissed: true)
        render json: { success: true, id: @job.id }
      end

      private

      def set_job
        @job = TrackedJob.find(params[:id])
      end
    end
  end
end
