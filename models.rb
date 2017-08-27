Encoding.default_internal = Encoding.default_external = 'UTF-8'
require_relative '.env' if File.file?(File.expand_path("../.env.rb", __FILE__))
require 'logger'
require 'sequel'

Sequel.extension :blank, :pg_array, :pg_row, :pg_array_ops, :pg_row_ops

module Falcom
  if ENV['RACK_ENV'] == 'test'
    DB = Sequel.connect(ENV['FALCOMCDS_TEST_DATABASE_URL'])
    logger = Logger.new($stdout)
    logger.level = Logger::WARN
    DB.logger = logger
  else
    DB = Sequel.connect(ENV['FALCOMCDS_DATABASE_URL'] || ENV['DATABASE_URL'])
  end
  DB.extension :pg_array, :pg_row

  Model = Class.new(Sequel::Model)
  Model.db = DB
  Model.def_Model(self)
  Model.plugin :forme
  Model.plugin :subclasses

  ADMIN = ENV['FALCOMCDS_ADMIN']
end

%w'track album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song'.each{|x| require_relative "models/#{x}"}
Falcom::Model.freeze_descendents
Falcom::DB.freeze
