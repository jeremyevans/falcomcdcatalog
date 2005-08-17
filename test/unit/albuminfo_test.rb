require File.dirname(__FILE__) + '/../test_helper'

class AlbuminfoTest < Test::Unit::TestCase
  fixtures :albuminfos

  def setup
    @albuminfo = Albuminfo.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Albuminfo,  @albuminfo
  end
end
