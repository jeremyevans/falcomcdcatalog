require 'rubygems'
require 'logger'
$:.unshift('/data/code/sequel/lib')
require 'sequel'
DB = Sequel.sqlite('falcomcdcatalog.sqlite3')

%w'album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song track'.each{|x| require "models/#{x}"}
