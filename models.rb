Encoding.default_internal = Encoding.default_external = 'UTF-8' if RUBY_VERSION >= '1.9'
require 'rubygems'
require 'logger'
$: << File.dirname(__FILE__)
$:.unshift('/data/code/sequel/lib')
require 'sequel/no_core_ext'
Sequel.extension :blank, :pg_auto_parameterize, :pg_statement_cache
Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :prepared_statements_associations
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres:///fcc?user=postgres')
DB.optimize_model_load = true
DB.extend Sequel::Postgres::AutoParameterize::DatabaseMethods
DB.extend Sequel::Postgres::StatementCache::DatabaseMethods
ADMIN = !ENV['DATABASE_URL']
#DB.logger = Logger.new($stdout)

%w'album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song track'.each{|x| require "models/#{x}"}
