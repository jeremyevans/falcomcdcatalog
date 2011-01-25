#encoding: UTF-8
class Lyric < Sequel::Model(:lyricsongs)
  one_to_one :song, :key=>:lyricid
  one_to_many :lyric_verses, :key=>:lyricsongid, :order=>[:languageid, :number]
  one_to_many :english_verses, :class_name=>'LyricVerse', :key=>:lyricsongid, :order=>:number, :conditions=>{:languageid=>1}
  one_to_many :romaji_verses, :clone=>:english_verses, :conditions=>{:languageid=>2}
  one_to_many :japanese_verses, :clone=>:english_verses, :conditions=>{:languageid=>3}
  many_to_one :composer, :class_name=>'Artist', :key=>:composer_id
  many_to_one :arranger, :class_name=>'Artist', :key=>:arranger_id
  many_to_one :vocalist, :class_name=>'Artist', :key=>:vocalist_id
  many_to_one :lyricist, :class_name=>'Artist', :key=>:lyricist_id
  
  @scaffold_fields = [:rsongname, :jsongname, :joriginalsongname, :arranger, :composer, :lyricist, :vocalist]
  @scaffold_select_order = :song__name
  @scaffold_include = :song
  @scaffold_browse_include = :song
  @scaffold_associations = [:song, :arranger, :composer, :lyricist, :vocalist, :english_verses, :romaji_verses, :japanese_verses]
  @scaffold_use_eager_graph = true
  
  def scaffold_name
    song.name
  end
     
  def has_japanese_verses?
    !japanese_verses.empty?
  end
  
  def japanese_title
    "#{jsongname} \357\274\210#{song.game.jname rescue nil}#{"\343\200\214#{joriginalsongname}\343\200\215" if joriginalsongname != song.name}\357\274\211"
  end
  
  def title
    "#{song.name} (#{song.game.name rescue nil}#{" - #{song.arrangement.name}" if song.arrangementof})"
  end
end
