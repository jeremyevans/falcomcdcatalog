class Artist < Sequel::Model
  def songs
    Song.join(Lyric, :id=>:lyricid).filter(id=>[:composer_id, :arranger_id, :vocalist_id, :lyricist_id]).order(:songs__name)
  end
end
