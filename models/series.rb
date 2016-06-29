module Falcom
class Series < Model
  many_to_many :albums, :left_key=>:seriesid, :join_table=>:seriesalbums, :right_key=>:albumid, :order=>:sortname
  one_to_many :games, :key=>:seriesid, :order=>:name
end
end

# Table: series
# Columns:
#  id   | integer | PRIMARY KEY DEFAULT nextval('series_id_seq'::regclass)
#  name | text    |
# Indexes:
#  series_pkey | PRIMARY KEY btree (id)
