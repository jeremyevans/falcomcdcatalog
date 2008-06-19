class Artist < Sequel::Model
  def songs
    Song.select(:songs.*).join(Lyric, :id=>:lyricid, id=>[:composer_id, :arranger_id, :vocalist_id, :lyricist_id]).order(:songs__name).all
  end
end
