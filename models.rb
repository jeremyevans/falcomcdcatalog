require_relative 'db'

module Falcom
  if ENV['RACK_ENV'] == 'test'
    require 'logger'
    logger = Logger.new($stdout)
    logger.level = Logger::WARN
    DB.logger = logger
  end

  Model = Class.new(Sequel::Model)
  Model.db = DB
  Model.def_Model(self)
  Model.plugin :forme
  Model.plugin :subclasses
  Model.plugin :pg_auto_constraint_validations
  Model.plugin :auto_restrict_eager_graph
  Model.plugin :require_valid_schema
  if ENV['UNUSED_ASSOCIATION_COVERAGE']
    Model.plugin :unused_associations, :coverage_file=>'unused_associations_coverage.json', :file=>'unused_associations.json'
  end
  if ENV['RACK_ENV'] == 'test'
    Model.plugin :forbid_lazy_load
    Model.plugin :instance_specific_default, :warn
  end

  ADMIN = ENV['FALCOMCDS_ADMIN']
end

%w'track album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song'.each{|x| require_relative "models/#{x}"}
