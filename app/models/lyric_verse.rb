class LyricVerse < Sequel::Model(:lyricverses)
    one_to_many :lyric, :key=>:lyricsongid
    @scaffold_fields = [:lyric, :number, :verse, :languageid]
    @scaffold_select_order = [:lyricsongid, :languageid, :number, :verse]

    def scaffold_name
      "Verse #{number} - #{languageid != 3 ? verse[0...40].gsub(/<br? ?\/?>?/, ', ') : 'Japanese text'}"
    end
end
