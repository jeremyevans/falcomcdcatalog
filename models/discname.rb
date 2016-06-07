class Discname < Sequel::Model
  many_to_one :album, :key => :albumid
end

# Table: discnames
# Columns:
#  id      | integer | PRIMARY KEY DEFAULT nextval('discnames_id_seq'::regclass)
#  albumid | integer |
#  number  | integer |
#  name    | text    |
# Indexes:
#  discnames_pkey | PRIMARY KEY btree (id)
