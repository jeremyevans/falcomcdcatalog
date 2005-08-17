require File.dirname(__FILE__) + '/../test_helper'

class MediaTest < Test::Unit::TestCase
  fixtures :medias

  def setup
    @media = Media.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Media,  @media
  end
end
