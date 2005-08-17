require File.dirname(__FILE__) + '/../test_helper'

class MediatypeTest < Test::Unit::TestCase
  fixtures :mediatypes

  def setup
    @mediatype = Mediatype.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Mediatype,  @mediatype
  end
end
