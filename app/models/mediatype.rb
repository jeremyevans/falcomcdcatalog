class Mediatype < ActiveRecord::Base
  has_many :media, :foreign_key=>'mediatypeid', :order=>'publicationdate'
  @scaffold_select_order = 'name'
  @scaffold_fields = [:name]
end
