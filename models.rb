require 'rubygems'
require 'logger'
$:.unshift('/data/code/sequel/lib')
require 'sequel'
Sequel.extension :blank
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres:///fcc?user=postgres')
ADMIN = !ENV['DATABASE_URL']

%w'album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song track'.each{|x| require "models/#{x}"}
