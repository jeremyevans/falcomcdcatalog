require File.dirname(__FILE__) + '/../test_helper'

class LyricTest < Test::Unit::TestCase
  fixtures :lyrics

  def setup
    @lyric = Lyric.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Lyric,  @lyric
  end
end
