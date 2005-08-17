class Lyric < ActiveRecord::Base
    set_table_name 'lyricsongs'
    has_one :song, :foreign_key=>'lyricid'
    has_many :lyric_verses, :foreign_key=>'lyricsongid', :order=>'number'
    belongs_to :composer, :foreign_key=>'composer'
    belongs_to :arranger, :foreign_key=>'arranger'
    belongs_to :vocalist, :foreign_key=>'vocalist'
    belongs_to :lyricist, :foreign_key=>'lyricist'
    @has_japanese_verses = nil
    @english_verses = nil
    @japanese_verses = nil
    @romaji_verses = nil
    @scaffold_select_order = 'jsongname'
    def scaffold_name
      jsongname
    end
       
    def english_verses
        @english_verses ||= verses(1)
    end
    
    def has_japanese_verses?
        @has_japanese_verses = LyricVerse.find(:all, :conditions=>["languageid = 3 AND lyricsongid = ?", id], :limit=>1).length > 0 if @has_japanese_verses.nil?
        @has_japanese_verses
    end
    
    def japanese_verses
        @japanese_verses ||= verses(3)
    end

    def japanese_title
        "#{jsongname} （#{song.game.jname}%s）" % (joriginalsongname != song.name ? "「#{joriginalsongname}」" : '')
    end

    def romaji_verses
        @romaji_verses ||= verses(2)
    end
    
    def title
        "#{song.name} (#{song.game.name}%s)" % (song.arrangementof ? " - #{song.arrangement.name}" : '')
    end
    
    private
    def verses(type)
        LyricVerse.find(:all, :conditions=>["languageid = #{type} AND lyricsongid = ?", id], :order=>'number')
    end
end
