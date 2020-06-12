ENV['RACK_ENV'] = 'test'

begin
  require 'warning'
rescue LoadError
else
  $VERBOSE = true
  Warning.ignore(/warning: setting Encoding\.default_/, File.dirname(__dir__))
  Warning.ignore([:missing_ivar, :method_redefined], File.dirname(__dir__))
  Gem.path.each do |path|
    Warning.ignore([:missing_ivar, :method_redefined, :not_reached], path)
  end
end

require_relative 'models'

db_name = Falcom::DB.get{current_database.function} 
raise "Doesn't look like a test database (database name: #{db_name}), not running tests" unless db_name =~ /test\z/

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/global_expectations/autorun'
require 'minitest/hooks/default'
FALCOM_CD_CATALOG_TEST_SETUP.call if defined?(FALCOM_CD_CATALOG_TEST_SETUP)

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

