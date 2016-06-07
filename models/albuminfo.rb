module Falcom
class Albuminfo < Sequel::Model(DB)
  many_to_one :album, :key => :albumid
end
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
