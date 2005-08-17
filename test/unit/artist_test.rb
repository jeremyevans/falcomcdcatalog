require File.dirname(__FILE__) + '/../test_helper'

class ArtistTest < Test::Unit::TestCase
  fixtures :artists

  def setup
    @artist = Artist.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Artist,  @artist
  end
end
