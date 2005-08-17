require File.dirname(__FILE__) + '/../test_helper'

class PublisherTest < Test::Unit::TestCase
  fixtures :publishers

  def setup
    @publisher = Publisher.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Publisher,  @publisher
  end
end
