require File.dirname(__FILE__) + '/../test_helper'
require 'falcom_controller'

# Re-raise errors caught by the controller.
class FalcomController; def rescue_action(e) raise e end; end

class FalcomControllerTest < Test::Unit::TestCase
  def setup
    @controller = FalcomController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
