require File.dirname(__FILE__) + '/../test_helper'

class TrackTest < Test::Unit::TestCase
  fixtures :tracks

  def setup
    @track = Track.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Track,  @track
  end
end
