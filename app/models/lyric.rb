class Lyric < ActiveRecord::Base
  set_table_name 'lyricsongs'
  has_one :song, :foreign_key=>'lyricid'
  has_many :lyric_verses, :foreign_key=>'lyricsongid', :order=>'languageid, number'
  has_many :english_verses, :class_name=>'LyricVerse', :foreign_key=>'lyricsongid', :order=>'number', :conditions=>'languageid = 1'
  has_many :romaji_verses, :class_name=>'LyricVerse', :foreign_key=>'lyricsongid', :order=>'number', :conditions=>'languageid = 2'
  has_many :japanese_verses, :class_name=>'LyricVerse', :foreign_key=>'lyricsongid', :order=>'number', :conditions=>'languageid = 3'
  belongs_to :composer, :class_name=>'Artist', :foreign_key=>'composer_id'
  belongs_to :arranger, :class_name=>'Artist', :foreign_key=>'arranger_id'
  belongs_to :vocalist, :class_name=>'Artist', :foreign_key=>'vocalist_id'
  belongs_to :lyricist, :class_name=>'Artist', :foreign_key=>'lyricist_id'
  
  @scaffold_fields = %w'rsongname jsongname joriginalsongname arranger composer lyricist vocalist'
  @scaffold_select_order = 'songs.name'
  @scaffold_include = :song
  @scaffold_associations = %w'song arranger composer lyricist vocalist english_verses romaji_verses japanese_verses'
  def scaffold_name
    song.name
  end
     
  def has_japanese_verses?
    japanese_verses.length > 1
  end
  
  def japanese_title
      "#{jsongname} （#{song.game.jname rescue nil}%s）" % (joriginalsongname != song.name ? "「#{joriginalsongname}」" : '')
  end
  
  def title
      "#{song.name} (#{song.game.name rescue nil}%s)" % (song.arrangementof ? " - #{song.arrangement.name}" : '')
  end
end
