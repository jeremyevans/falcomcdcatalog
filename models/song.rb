class Song < Sequel::Model
  one_to_many :tracks, :key => :songid
  one_to_many :arrangements, :class_name=>'Song', :key=>:arrangementof
  many_to_one :game, :key=>:gameid
  many_to_one :lyric, :key=>:lyricid
  many_to_one :arrangement, :class_name=>'Song', :key=>:arrangementof

  @scaffold_select_order = :name
  @scaffold_fields = [:name, :game, :lyric, :arrangement]
  @scaffold_auto_complete_options = {}
  
  def scaffold_name
    name[0..50]
  end
end
