ENV['RAILS_ENV'] = 'test'

require 'rubygems'
require 'test/unit'
require 'fileutils'
require 'logger'
require 'ruby-debug'

require 'pathname_local'
require 'test_declarative'
require 'database_cleaner'

require 'active_record'
require 'rails/log_subscriber'
require 'active_record/railties/log_subscriber'
require 'active_support/core_ext/logger'

log = '/tmp/simple_taggable_test.log'
FileUtils.touch(log) unless File.exists?(log)
ActiveRecord::Base.logger = Logger.new(log)
Rails::LogSubscriber.add(:active_record, ActiveRecord::Railties::LogSubscriber.new)

DatabaseCleaner.strategy = :truncation

class Test::Unit::TestCase
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def assert_equivalent(expected, actual, message = nil)
    if expected.first.is_a?(ActiveRecord::Base)
      assert_equal expected.sort_by(&:id), actual.sort_by(&:id), message
    else
      assert_equal expected.sort, actual.sort, message
    end
  end

  def assert_tag_counts(tags, expected_values)
    tags.each do |tag|
      value = expected_values.delete(tag.name.to_sym)
      assert_not_nil value, "The tag #{tag.name.inspect} was not expected, but is actually present."
      assert_equal value, tag.count, "Expected value of #{value} for #{tag.name.inspect}, but was #{tag.count}"
    end

    unless expected_values.empty?
      assert false, "The following tag counts were expected but are not actually present: #{expected_values.inspect}"
    end
  end
end

$:.unshift Pathname.local('../lib').to_s

require 'simple_taggable'
include SimpleTaggable

require Pathname.local('models')
require Pathname.local('helpers/assert_queries')