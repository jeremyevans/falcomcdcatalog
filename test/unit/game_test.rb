require File.dirname(__FILE__) + '/../test_helper'

class GameTest < Test::Unit::TestCase
  fixtures :games

  def setup
    @game = Game.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Game,  @game
  end
end
