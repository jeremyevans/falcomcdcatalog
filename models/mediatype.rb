class Mediatype < Sequel::Model
  one_to_many :media, :key=>:mediatypeid, :order=>:publicationdate
end

# Table: mediatypes
# Columns:
#  id   | integer | PRIMARY KEY DEFAULT nextval('mediatypes_id_seq'::regclass)
#  name | text    |
# Indexes:
#  mediatypes_pkey | PRIMARY KEY btree (id)
