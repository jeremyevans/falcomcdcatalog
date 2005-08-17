class LyricVerse < ActiveRecord::Base
    set_table_name 'lyricverses'
    belongs_to :lyric, :foreign_key=>'lyricsongid'
end
