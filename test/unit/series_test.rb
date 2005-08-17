require File.dirname(__FILE__) + '/../test_helper'

class SeriesTest < Test::Unit::TestCase
  fixtures :series

  def setup
    @series = Series.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Series,  @series
  end
end
