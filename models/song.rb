class Song < Sequel::Model
  one_to_many :arrangements, :class_name=>'Song', :key=>:arrangementof
  many_to_one :game, :key=>:gameid
  many_to_one :lyric, :key=>:lyricid
  many_to_one :arrangement, :class_name=>'Song', :key=>:arrangementof

  def tracks
    return @tracks if @tracks
    @tracks = []
    song_id = id
    Album.where{{song_id=>Sequel.pg_array(song_ids(tracks)).any}}.each do |album|
      album[:tracks].select{|t| t.songid == song_id}.each do |track|
        track.album = album
        @tracks << track
      end
    end
    @tracks
  end
end

# Table: songs
# Columns:
#  id            | integer | PRIMARY KEY DEFAULT nextval('songs_id_seq'::regclass)
#  name          | text    |
#  gameid        | integer |
#  lyricid       | integer |
#  arrangementof | integer |
# Indexes:
#  songs_pkey          | PRIMARY KEY btree (id)
#  songs_name_index    | UNIQUE btree (name)
#  songs_lyricid_index | btree (lyricid)
# Referenced By:
#  track | track_songid_fkey | (songid) REFERENCES songs(id)
