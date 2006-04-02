class LyricVerse < ActiveRecord::Base
    set_table_name 'lyricverses'
    belongs_to :lyric, :foreign_key=>'lyricsongid'
    @scaffold_fields = %w'lyric number verse languageid'
    @scaffold_select_order = 'lyricsongid, languageid, number, verse'
    def scaffold_name
      "Verse #{number} - #{languageid != 3 ? verse[0...40].gsub(/<br? ?\/?>?/, ', ') : 'Japanese text'}"
    end
end
