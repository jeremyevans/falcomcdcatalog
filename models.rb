Encoding.default_internal = Encoding.default_external = 'UTF-8' if RUBY_VERSION >= '1.9'
require 'rubygems'
require 'logger'
$:.unshift('/data/code/sequel/lib')
require 'sequel'
Sequel.extension :blank
Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :prepared_statements_associations
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres:///fcc?user=postgres')
ADMIN = !ENV['DATABASE_URL']

%w'album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song track'.each{|x| require "models/#{x}"}
