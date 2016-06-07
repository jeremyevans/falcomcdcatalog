class Album < Sequel::Model
  one_to_many :discnames, :key=>:albumid, :order=>:number
  one_to_many :albuminfos, :key=>:albumid, :order=>[:discnumber, :starttrack, Sequel.desc(:endtrack)]
  one_to_many :media, :key=>:albumid, :order=>:publicationdate
  many_to_many :games, :left_key=>:albumid, :join_table=>:gamealbums, :right_key=>:gameid
  many_to_many :series, :left_key=>:albumid, :join_table=>:seriesalbums, :right_key=>:seriesid
 
  def self.group_all_by_sortname(initial = nil)
    ds = initial ? where(Sequel.like(:sortname, "#{initial}%")) : self
    ds.order(:sortname).collect{|album| [nil, album, album.sortname[0...1]]}
  end
 
  def <=>(other)
    sortname <=> other.sortname
  end

  def tracks_dataset
    Track.from(:albums).
      where(:id=>id).
      select(:id___albumid, Sequel.pg_array(:tracks).unnest.as(:t)).
      from_self(:alias=>:tracks).
      select(:albumid, Sequel.pg_row(:tracks__t).*).
      from_self(:alias=>:tracks)
  end

  def tracks
    ts = super
    if ts
      # Eagerly load the songs
      id_map = {}
      song_ids = ts.map do |t|
        (id_map[t.songid] ||= []) << t
        t.songid
      end
      Song.where(:id=>song_ids).each do |s|
        id_map[s.id].each do |t|
          t.associations[:song] = s
        end
      end
      ts
    else
      []
    end
  end

  def create_tracklist(tracklist)
    unless tracks.empty?
      raise Sequel::Error, 'already created a tracklist for this album'
    end

    songs = Song.select_hash(Sequel.function(:replace, Sequel.function(:lower, :name), ' ', '').as(:name), :id)
    disctracklists = tracklist.strip.gsub("\r", "").split(/\n\n+/)
    DB.transaction do
      tracks = []
      disctracklists.each_with_index do |tracklist, i| i+=1
        Discname.create(:albumid=>id, :number=>i, :name=>"Disc #{i}") if disctracklists.length > 1
        tracklist.split("\n").each_with_index do |track, j| j+=1
          track = track.strip.gsub('&', "&amp;").gsub('"', "&quot;")
          lc_name = track.downcase.gsub(/\s/, "")
          songid = track == '-' ? 1 : (songs[lc_name] || (songs[lc_name] = Song.create(:name=>track).id)) 
          tracks << DB.row_type(:track, [i, j, songid])
        end
      end
      update(:tracks=>Sequel.pg_array(tracks))
    end
  end

  def update_tracklist_game(disc, start_track, end_track, game_id)
    song_ids = tracks_dataset.where(:discnumber=>disc, :number=>(start_track..end_track)).select(:songid)
    Song.where(:id=>song_ids).update(:gameid=>game_id)
  end
end

# Table: albums
# Columns:
#  id       | integer | PRIMARY KEY DEFAULT nextval('albums_id_seq'::regclass)
#  sortname | text    |
#  picture  | text    |
#  info     | text    |
#  numdiscs | integer |
#  fullname | text    |
#  tracks   | track[] |
# Indexes:
#  albums_pkey    | PRIMARY KEY btree (id)
#  album_song_ids | gin (song_ids(tracks))
