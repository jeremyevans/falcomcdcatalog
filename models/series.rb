class Series < Sequel::Model
  many_to_many :albums, :left_key=>:seriesid, :join_table=>:seriesalbums, :right_key=>:albumid, :order=>:sortname
  one_to_many :games, :key=>:seriesid, :order=>:name
end
