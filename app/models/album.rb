class Album < Sequel::Model
  one_to_many :tracks, :key=>:albumid, :order=>[:discnumber, :number], :eager=>[:song, :album]
  one_to_many :discnames, :key=>:albumid, :order=>:number
  one_to_many :albuminfos, :key=>:albumid, :order=>[:discnumber, :starttrack, :endtrack.desc]
  one_to_many :media, :key=>:albumid, :order=>:publicationdate
  many_to_many :games, :left_key=>:albumid, :join_table=>:gamealbums, :right_key=>:gameid
  many_to_many :series, :left_key=>:albumid, :join_table=>:seriesalbums, :right_key=>:seriesid
  @scaffold_select_order = :sortname
  @scaffold_fields = [:fullname, :sortname, :picture, :numdiscs]
 
  def self.group_all_by_sortname(initial = nil)
    ds = initial ? filter(:fullname.like("#{initial}%")) : self
    ds.order(:sortname).collect{|album| ['', album, album.sortname[0...1]]}.uniq
  end
 
  def scaffold_name
    fullname
  end
  
  def <=>(other)
    fullname <=> other.fullname
  end
end
