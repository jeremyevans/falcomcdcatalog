require 'rubygems'
require 'logger'
$:.unshift('/data/code/sequel/lib')
require 'sequel'
require 'config'

%w'album albuminfo artist discname game lyric lyric_verse mediatype medium publisher series song track'.each{|x| require "models/#{x}"}
