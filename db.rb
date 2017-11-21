Encoding.default_internal = Encoding.default_external = 'UTF-8'

begin
  require_relative '.env'
rescue LoadError
end

require 'sequel'

Sequel.extension :blank, :pg_array, :pg_row, :pg_array_ops, :pg_row_ops

module Falcom
  url = if ENV['RACK_ENV'] == 'test'
    ENV.delete('FALCOMCDS_TEST_DATABASE_URL')
  else
    ENV.delete('FALCOMCDS_DATABASE_URL') || ENV.delete('DATABASE_URL')
  end

  DB = Sequel.connect(url)
  DB.extension :pg_array, :pg_row
end
