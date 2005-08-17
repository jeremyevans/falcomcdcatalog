require File.dirname(__FILE__) + '/../test_helper'

class DiscnameTest < Test::Unit::TestCase
  fixtures :discnames

  def setup
    @discname = Discname.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Discname,  @discname
  end
end
