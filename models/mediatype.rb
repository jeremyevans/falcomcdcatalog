class Mediatype < Sequel::Model
  one_to_many :media, :key=>:mediatypeid, :order=>:publicationdate
  @scaffold_select_order = :name
  @scaffold_fields = [:name]
end
