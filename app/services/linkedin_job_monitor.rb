# backend/app/services/linkedin_job_monitor.rb
require "httparty"
require "nokogiri"

class LinkedinJobMonitor
  BASE_URL = "https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search"

  def initialize(keywords: "Ruby on Rails", location: "Remote")
    @keywords = keywords
    @location = location
  end

  def fetch_recent_jobs
    query = {
      keywords: @keywords,
      location: @location,
      f_TPR: "r86400", # Past 24 hours
      start: 0
    }

    headers = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
      "Accept-Language" => "en-US,en;q=0.9"
    }

    response = HTTParty.get(BASE_URL, query: query, headers: headers, timeout: 15)
    return [] unless response.code == 200

    parse_job_cards(response.body)
  rescue StandardError => e
    Rails.logger.error("[LinkedinJobMonitor] Failed to fetch: #{e.message}")
    []
  end

  private

  def parse_job_cards(html)
    doc = Nokogiri::HTML(html)
    jobs = []

    doc.css("li").each do |card|
      title_elem = card.at_css(".base-search-card__title")
      company_elem = card.at_css(".base-search-card__subtitle")
      location_elem = card.at_css(".job-search-card__location")
      link_elem = card.at_css(".base-card__full-link")
      time_elem = card.at_css("time")

      next unless link_elem && title_elem

      url = link_elem["href"].split("?").first
      job_id = card.at_css("div[data-entity-urn]")&.[]("data-entity-urn")&.split(":")&.last || url.scan(/\d{8,}/).first

      next if job_id.blank?

      jobs << {
        linkedin_job_id: job_id,
        title: title_elem.text.strip,
        company: company_elem&.text&.strip || "Unknown Company",
        location: location_elem&.text&.strip || @location,
        url: url,
        description: fetch_description(url),
        posted_at: time_elem ? Time.zone.parse(time_elem["datetime"]) : Time.current,
        notified: false,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    jobs
  end

  def fetch_description(url)
    response = HTTParty.get(
      url,
      headers: {
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        "Accept-Language" => "en-US,en;q=0.9"
      },
      timeout: 15
    )
    unless response.code == 200
      Rails.logger.warn("[LinkedinJobMonitor] Description request failed with status #{response.code} for #{url}")
      return
    end

    parse_description(response.body)
  rescue StandardError => e
    Rails.logger.warn("[LinkedinJobMonitor] Failed to fetch description for #{url}: #{e.message}")
    nil
  end

  def parse_description(html)
    doc = Nokogiri::HTML(html)
    description = doc.at_css(".show-more-less-html__markup, .description__text, .description__text--rich")
    description&.xpath(".//text()")&.map(&:text)&.join(" ")&.squish
  end
end
