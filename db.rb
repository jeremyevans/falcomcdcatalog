begin
  require_relative '.env'
rescue LoadError
end

require 'sequel'


module Falcom
  url = if ENV['RACK_ENV'] == 'test'
    ENV.delete('FALCOMCDS_TEST_DATABASE_URL')
  else
    ENV.delete('FALCOMCDS_DATABASE_URL') || ENV.delete('DATABASE_URL')
  end

  DB = Sequel.connect(url)
  Sequel.extension :blank, :pg_array, :pg_row, :pg_array_ops, :pg_row_ops
  DB.extension :pg_array, :pg_row
end
