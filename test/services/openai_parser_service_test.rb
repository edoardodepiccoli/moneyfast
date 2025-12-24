require "test_helper"

class OpenaiParserServiceTest < ActiveSupport::TestCase
  test "returns result object with success flag" do
    skip "Requires OpenAI API key and network access"
    # This test would require mocking the OpenAI client
    # service = OpenaiParserService.new("spent 50 euros")
    # result = service.parse
    # assert result.is_a?(OpenaiParserService::Result)
  end

  test "validates required keys in response" do
    skip "Requires OpenAI API key and network access"
    # Test would verify that invalid responses are caught
  end
end

