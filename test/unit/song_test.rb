require File.dirname(__FILE__) + '/../test_helper'

class SongTest < Test::Unit::TestCase
  fixtures :songs

  def setup
    @song = Song.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Song,  @song
  end
end
