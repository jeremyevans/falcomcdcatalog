class LyricVerse < Sequel::Model(:lyricverses)
  many_to_one :lyric, :key=>:lyricsongid
end
