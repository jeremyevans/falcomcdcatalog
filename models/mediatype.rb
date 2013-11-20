class Mediatype < Sequel::Model
  one_to_many :media, :key=>:mediatypeid, :order=>:publicationdate
end
