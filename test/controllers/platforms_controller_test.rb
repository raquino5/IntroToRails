require "test_helper"

class PlatformsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get platforms_show_url
    assert_response :success
  end
end
