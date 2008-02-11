class Series < ActiveRecord::Base
  has_and_belongs_to_many :albums, :foreign_key=>'seriesid', :join_table=>'seriesalbums', :association_foreign_key=>'albumid', :order=>'sortname'
  has_many :games, :foreign_key=>'seriesid', :order=>'name'
  @scaffold_select_order = 'name'
  @scaffold_fields = [:name]
end
