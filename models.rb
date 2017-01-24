Encoding.default_internal = Encoding.default_external = 'UTF-8' if RUBY_VERSION >= '1.9'
require 'rubygems'
require 'logger'
env_file = File.expand_path("../.env.rb", __FILE__)
require env_file if File.file?(env_file)

require 'sequel'

module Falcom
  DB = Sequel.connect(ENV['FALCOMCDS_DATABASE_URL'] || ENV['DATABASE_URL'], :identifier_mangling=>false)
  DB.extension(:freeze_datasets, :pg_array, :pg_row)

  Sequel.extension :blank, :pg_array_ops, :pg_row_ops
  Model = Class.new(Sequel::Model)
  Model.db = DB
  #Model.def_Model(self)
  def self.Model(table)
    c = Class.new(Model)
    c.set_dataset(table)
    c
  end
  DB.optimize_model_load = true if DB.respond_to?(:optimize_model_load=)

  ADMIN = ENV['FALCOMCDS_ADMIN']
  # DB.logger = Logger.new($stdout)
end

%w'track album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song'.each{|x| require File.expand_path("../models/#{x}", __FILE__)}
