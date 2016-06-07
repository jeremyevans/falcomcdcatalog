module Falcom
class Discname < Sequel::Model(DB)
  many_to_one :album, :key => :albumid
end
end

# Table: discnames
# Columns:
#  id      | integer | PRIMARY KEY DEFAULT nextval('discnames_id_seq'::regclass)
#  albumid | integer |
#  number  | integer |
#  name    | text    |
# Indexes:
#  discnames_pkey | PRIMARY KEY btree (id)
