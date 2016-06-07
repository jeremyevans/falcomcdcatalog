Encoding.default_internal = Encoding.default_external = 'UTF-8' if RUBY_VERSION >= '1.9'
require 'rubygems'
require 'logger'
env_file = File.expand_path("../.env.rb", __FILE__)
require env_file if File.file?(env_file)

require 'sequel'

module Falcom; end
Falcom::DB = Sequel.connect(ENV['FALCOMCDS_DATABASE_URL'] || ENV['DATABASE_URL'])

Falcom::DB.extension(:pg_array, :pg_row)
Sequel.extension :blank, :pg_array_ops, :pg_row_ops
Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :prepared_statements_associations
Falcom::DB.optimize_model_load = true if Falcom::DB.respond_to?(:optimize_model_load=)

ADMIN = ENV['FALCOMCDS_ADMIN']
# Falcom::DB.logger = Logger.new($stdout)

%w'track album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song'.each{|x| require File.expand_path("../models/#{x}", __FILE__)}
