class Song < ActiveRecord::Base
  has_many :tracks, :foreign_key => 'songid'
  belongs_to :game, :foreign_key=>'gameid'
  belongs_to :lyric, :foreign_key=>'lyricid'
  belongs_to :arrangement, :class_name=>'Song', :foreign_key=>'arrangementof'
  has_many :arrangements, :class_name=>'Song', :foreign_key=>'arrangementof'

  @scaffold_select_order = 'songs.name'
  @scaffold_fields = [:name, :game, :lyric, :arrangement]
  @scaffold_auto_complete_options = {}
  
  def scaffold_name
    name[0..50]
  end
end
