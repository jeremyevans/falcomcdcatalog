class Track < ActiveRecord::Base
  belongs_to :song, :foreign_key => 'songid'
  belongs_to :album, :foreign_key => 'albumid'
  @scaffold_fields = %w'album discnumber number song'

  def album_and_number
      "#{album.fullname}, %sTrack #{number}" % (album.numdiscs > 1 ? "Disc #{discnumber}, " : '')
  end
end
