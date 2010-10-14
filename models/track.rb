class Track < Sequel::Model
  many_to_one :song, :key => :songid
  many_to_one :album, :key => :albumid
  @scaffold_fields = [:album, :discnumber, :number, :song]
  @scaffold_include = [:song, :album]
  @scaffold_auto_complete_options = {:sql_name=>'song.name'}
  @scaffold_use_eager_graph = true

  def album_and_number
    "#{album.fullname}, #{"Disc #{discnumber}, " if album.numdiscs > 1}Track #{number}"
  end
  
  def scaffold_name
    "#{album.fullname}-#{discnumber}-#{number}-#{song.name}"
  end
end
