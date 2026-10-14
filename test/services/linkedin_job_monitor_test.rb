require "test_helper"

class LinkedinJobMonitorTest < ActiveSupport::TestCase
  test "parses the full job description from a job details page" do
    details_html = <<~HTML
      <div class="show-more-less-html__markup">
        Build reliable systems<br>Work with the team
      </div>
    HTML

    description = LinkedinJobMonitor.new.send(:parse_description, details_html)

    assert_equal "Build reliable systems Work with the team", description
  end
end
