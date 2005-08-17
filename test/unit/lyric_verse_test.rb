require File.dirname(__FILE__) + '/../test_helper'

class LyricVerseTest < Test::Unit::TestCase
  fixtures :lyric_verses

  def setup
    @lyric_verse = LyricVerse.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of LyricVerse,  @lyric_verse
  end
end
