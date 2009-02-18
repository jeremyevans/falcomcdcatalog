require 'rubygems'
require 'sequel'
DB = Sequel.postgres('falcomcdcatalog', :user=>'_postgresql')
NEWDB = Sequel.sqlite('falcomcdcatalog.sqlite3')
[:albums, :albuminfos, :artists, :discnames, :series, :games, :languages, :lyricsongs, :lyricverses, :mediatypes, :publishers, :media, :songs, :tracks, :seriesalbums, :gamealbums].each do |table|
  print  "Converting #{table}: #{DB[table].count} records read, "
  DB[table].each{|row| NEWDB[table].insert(row)}
  puts "#{NEWDB[table].count} written"
end
