require File.dirname(__FILE__) + '/../test_helper'

class AlbumTest < Test::Unit::TestCase
  fixtures :albums

  def setup
    @album = Album.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Album,  @album
  end
end
