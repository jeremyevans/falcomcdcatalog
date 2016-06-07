class Track < Sequel::Model(:track)
  plugin :pg_row
  many_to_one :song, :key => :songid

  attr_accessor :album

  def album_and_number
    "#{album.fullname}, #{"Disc #{discnumber}, " if album.numdiscs > 1}Track #{number}"
  end
end

# Table: track
# Columns:
#  discnumber | integer |
#  number     | integer |
#  songid     | integer |
# Foreign key constraints:
#  track_songid_fkey | (songid) REFERENCES songs(id)
