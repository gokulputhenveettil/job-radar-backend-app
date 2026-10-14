# backend/app/services/cover_letter_generator.rb
require "httparty"

class CoverLetterGenerator
  OPENAI_API_KEY = Rails.application.credentials.openai_api_key || ENV["OPENAI_API_KEY"]

  def initialize(tracked_job:, format_type: "inmail")
    @job = tracked_job
    @format_type = format_type # "inmail" or "formal"
    @resume_text = File.read(Rails.root.join("config", "master_resume.md"))
  end

  def call
    raise "OpenAI API key is not configured" if OPENAI_API_KEY.blank?
    raise "Job description is not available" if @job.description.blank?
    raise "Unsupported cover letter format: #{@format_type}" unless %w[inmail formal].include?(@format_type)

    prompt = build_prompt
    response = HTTParty.post(
      "https://api.openai.com/v1/chat/completions",
      headers: {
        "Authorization" => "Bearer #{OPENAI_API_KEY}",
        "Content-Type" => "application/json"
      },
      body: {
        model: "gpt-4o-mini",
        messages: [ { role: "user", content: prompt } ],
        temperature: 0.4
      }.to_json,
      timeout: 30
    )

    unless response.success?
      provider_error = JSON.parse(response.body).dig("error", "message") rescue nil
      message = provider_error.presence || response.message
      raise "OpenAI request failed (HTTP #{response.code}): #{message}"
    end

    parsed = JSON.parse(response.body)
    content = parsed.dig("choices", 0, "message", "content")&.strip
    raise "OpenAI response did not include generated content" if content.blank?

    content
  end

  private

  def build_prompt
    if @format_type == "inmail"
      <<~PROMPT
        You are a seasoned software engineering applicant. Draft a concise, high-impact LinkedIn InMail outreach message (under 180 words) addressed to the hiring manager or recruiter.

        Target Role: #{@job.title} at #{@job.company}
        Job Description:
        #{@job.description.truncate(3500)}

        Candidate Background & Resume:
        #{@resume_text}

        Guidelines:
        - Do not use generic buzzwords ("I was thrilled to see...", "synergies").
        - Hook with 2 relevant accomplishments that directly solve requirements in the job description.
        - End with a low-friction call-to-action.
        - Output only the text of the message ready to send.
      PROMPT
    else
      <<~PROMPT
        Write a professional, 3-paragraph cover letter for:
        Target Role: #{@job.title} at #{@job.company}

        Job Description:
        #{@job.description.truncate(3500)}

        Candidate Resume:
        #{@resume_text}

        Paragraph 1: Intent, role target, and immediate value proposition.
        Paragraph 2: Deep technical alignment with 2 specific challenges mentioned in the description.
        Paragraph 3: Confident sign-off and availability.
      PROMPT
    end
  end
end
