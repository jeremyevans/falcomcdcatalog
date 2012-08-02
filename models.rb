Encoding.default_internal = Encoding.default_external = 'UTF-8' if RUBY_VERSION >= '1.9'
require 'rubygems'
require 'logger'
$: << File.dirname(__FILE__)
$:.unshift('/data/code/sequel/lib')
require 'sequel/no_core_ext'
Sequel.extension :blank, :pg_array_ops, :pg_row_ops
Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :prepared_statements_associations
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres:///fcc?user=postgres')
DB.extension(:pg_array, :pg_row)
DB.optimize_model_load = true
ADMIN = !ENV['DATABASE_URL']
# DB.logger = Logger.new($stdout)

%w'track album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song'.each{|x| require "models/#{x}"}
