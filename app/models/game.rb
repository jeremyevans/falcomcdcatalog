class Game < ActiveRecord::Base
  belongs_to :series, :foreign_key=>'seriesid', :order=>'name'
  has_many :songs, :foreign_key=>'gameid', :order=>'name'
  has_and_belongs_to_many :albums, :foreign_key=>'gameid', :join_table=>'gamealbums', :association_foreign_key=>'albumid', :order=>'sortname'
  @scaffold_select_order = 'name'
  @scaffold_fields = [:series, :name, :jname]
end
