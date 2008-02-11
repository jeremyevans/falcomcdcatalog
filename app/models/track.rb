class Track < ActiveRecord::Base
  belongs_to :song, :foreign_key => 'songid'
  belongs_to :album, :foreign_key => 'albumid'
  @scaffold_fields = [:album, :discnumber, :number, :song]
  @scaffold_include = [:song, :album]
  @scaffold_auto_complete_options = {}

  def album_and_number
    "#{album.fullname}, %sTrack #{number}" % (album.numdiscs > 1 ? "Disc #{discnumber}, " : '')
  end
  
  def scaffold_name
    "#{album.fullname}-#{discnumber}-#{number}-#{song.name}"
  end
end
