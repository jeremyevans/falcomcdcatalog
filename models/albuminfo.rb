class Albuminfo < Sequel::Model
  many_to_one :album, :key => :albumid
end

# Table: albuminfos
# Columns:
#  id         | integer | PRIMARY KEY DEFAULT nextval('albuminfos_id_seq'::regclass)
#  albumid    | integer |
#  discnumber | integer |
#  starttrack | integer |
#  endtrack   | integer |
#  info       | text    |
# Indexes:
#  albuminfos_pkey | PRIMARY KEY btree (id)
