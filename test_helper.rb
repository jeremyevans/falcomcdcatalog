ENV['RACK_ENV'] = 'test'
require_relative 'models'

db_name = Falcom::DB.get{current_database.function} 
raise "Doesn't look like a test database (database name: #{db_name}), not running tests" unless db_name =~ /test\z/

gem 'minitest'
require 'minitest/autorun'
require 'minitest/hooks/default'

class Minitest::HooksSpec
  around(:all) do |&block|
    Falcom::DB.transaction(:rollback=>:always){super(&block)}
  end

  around do |&block|
    Falcom::DB.transaction(:rollback=>:always, :savepoint=>true){super(&block)}
  end

  def log
    Falcom::DB.loggers.first.level = Logger::INFO
    yield
  ensure
    Falcom::DB.loggers.first.level = Logger::WARN
  end
end

