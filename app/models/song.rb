class Song < ActiveRecord::Base
  has_many :tracks, :foreign_key => 'songid'
  belongs_to :game, :foreign_key=>'gameid'
  belongs_to :lyric, :foreign_key=>'lyricid'
  belongs_to :arrangement, :foreign_key=>'arrangementof'
  has_many :arrangements, :foreign_key=>'arrangementof'

  @scaffold_select_order = 'name'
  @scaffold_fields = %w'name game lyric arrangement'
  
  def scaffold_name
    name[0..50]
  end
end
