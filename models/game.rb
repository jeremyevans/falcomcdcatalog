class Game < Sequel::Model
  many_to_one :series, :key=>:seriesid
  one_to_many :songs, :key=>:gameid, :order=>:name
  many_to_many :albums, :left_key=>:gameid, :join_table=>:gamealbums, :right_key=>:albumid, :order=>:sortname
  @scaffold_select_order = :name
  @scaffold_fields = [:series, :name, :jname]
end
