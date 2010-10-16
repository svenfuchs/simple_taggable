require File.dirname(__FILE__) + '/test_helper'

class TagTest < Test::Unit::TestCase
  def setup
    DatabaseCleaner.start
    load File.expand_path('../fixtures.rb', __FILE__)
  end

  test "named_like" do
    assert_equal 'great', Tag.named_like('great').first.name
  end

  test "named_like_any_of" do
    assert_equal ['great', 'nature'], Tag.named_like_any_of(['great', 'nature']).map(&:name)
  end
end
