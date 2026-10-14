# backend/app/services/linkedin_description_fetcher.rb
require "httparty"
require "nokogiri"

class LinkedinDescriptionFetcher
  def self.call(url)
    headers = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    }
    response = HTTParty.get(url, headers: headers, timeout: 10)
    return nil unless response.code == 200

    doc = Nokogiri::HTML(response.body)
    elem = doc.at_css(".show-more-less-html__markup") || doc.at_css(".description__text")
    elem&.text&.strip
  rescue StandardError => e
    Rails.logger.error("[LinkedinDescriptionFetcher] Failed: #{e.message}")
    nil
  end
end
