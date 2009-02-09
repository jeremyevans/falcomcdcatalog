class Lyric < Sequel::Model(:lyricsongs)
  one_to_many :songs, :key=>:lyricid, :one_to_one=>true
  one_to_many :lyric_verses, :key=>:lyricsongid, :order=>[:languageid, :number]
  one_to_many :english_verses, :class_name=>'LyricVerse', :key=>:lyricsongid, :order=>:number, :graph_conditions=>{:languageid=>1} do |ds|
    ds.filter(:languageid=>1)
  end
  one_to_many :romaji_verses, :class_name=>'LyricVerse', :key=>:lyricsongid, :order=>:number, :graph_conditions=>{:languageid=>2} do |ds|
    ds.filter(:languageid=>2)
  end
  one_to_many :japanese_verses, :class_name=>'LyricVerse', :key=>:lyricsongid, :order=>:number, :graph_conditions=>{:languageid=>3} do |ds|
    ds.filter(:languageid=>3)
  end
  many_to_one :composer, :class_name=>'Artist', :key=>:composer_id
  many_to_one :arranger, :class_name=>'Artist', :key=>:arranger_id
  many_to_one :vocalist, :class_name=>'Artist', :key=>:vocalist_id
  many_to_one :lyricist, :class_name=>'Artist', :key=>:lyricist_id
  
  @scaffold_fields = [:rsongname, :jsongname, :joriginalsongname, :arranger, :composer, :lyricist, :vocalist]
  @scaffold_select_order = :name
  @scaffold_include = :songs
  @scaffold_browse_include = :songs
  @scaffold_associations = [:songs, :arranger, :composer, :lyricist, :vocalist, :english_verses, :romaji_verses, :japanese_verses]
  
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
