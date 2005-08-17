class Album < ActiveRecord::Base
  has_many :tracks, :foreign_key=>'albumid', :order=>'discnumber, number' 
  has_many :discnames, :foreign_key=>'albumid', :order=>'number'
  has_many :albuminfos, :foreign_key=>'albumid', :order=>'discnumber, starttrack, endtrack DESC'
  has_many :media, :foreign_key=>'albumid', :order=>'publicationdate'
  has_and_belongs_to_many :games, :foreign_key=>'albumid', :join_table=>'gamealbums', :association_foreign_key=>'gameid'
  has_and_belongs_to_many :series, :foreign_key=>'albumid', :join_table=>'seriesalbums', :association_foreign_key=>'seriesid'
  @scaffold_select_order = 'sortname'
  @scaffold_fields = %w'fullname sortname picture numdiscs'
 
  def scaffold_name
    fullname
  end
  
  def <=>(other)
    fullname <=> other.fullname
  end
end
