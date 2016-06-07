class Game < Sequel::Model
  many_to_one :series, :key=>:seriesid
  one_to_many :songs, :key=>:gameid, :order=>:name
  many_to_many :albums, :left_key=>:gameid, :join_table=>:gamealbums, :right_key=>:albumid, :order=>:sortname
end

# Table: games
# Columns:
#  id       | integer | PRIMARY KEY DEFAULT nextval('games_id_seq'::regclass)
#  seriesid | integer |
#  name     | text    |
#  jname    | text    |
# Indexes:
#  games_pkey | PRIMARY KEY btree (id)
