require File.dirname(__FILE__) + '/../test_helper'

class ArrangementTest < Test::Unit::TestCase
  fixtures :arrangements

  def setup
    @arrangement = Arrangement.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Arrangement,  @arrangement
  end
end
