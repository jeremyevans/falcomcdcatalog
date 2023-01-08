require_relative 'test_helper'

include Falcom
Model.freeze_descendents
DB.freeze

describe Album do
  before do
    @album = Album.create(:fullname=>'A TestAlbum', :sortname=>'TestAlbum')
    @album2 = Album.create(:fullname=>'OtherAlbum', :sortname=>'OtherAlbum')
  end

  specify "associations be correct" do
    @album.tracks.must_equal []
    @album.discnames.must_equal []
    @album.albuminfos.must_equal []
    @album.media.must_equal []
    @album.games.must_equal []
    @album.series.must_equal []
  end

  specify ".group_all_by_sortname should give an array of arrays of nil, albums, and initals" do
    Album.group_all_by_sortname.must_equal [[nil, @album2, 'O'], [nil, @album, 'T']]
  end

  specify ".group_all_by_sortname should filter by initial if given an inital" do
    Album.group_all_by_sortname('T').must_equal [[nil, @album, 'T']]
  end

  specify "#<=> should go by sortname" do
    [@album, @album2].sort.must_equal [@album2, @album]
  end

  specify "#tracks_dataset should be a dataset for the album's tracks, including the album_id" do
    @album.tracks_dataset.all.must_equal []
    @album.update(:tracks=>[{:discnumber=>1, :number=>2, :songid=>1}])
    @album.tracks_dataset.all.must_equal [Track.load(:albumid=>@album.id, :discnumber=>1, :number=>2, :songid=>1)]
  end

  specify "#tracks should be an array of the tracks with eagerly loaded songs" do
    @album.tracks.must_equal []
    song = Song.create(:name=>'A Song')
    @album.update(:tracks=>[{:discnumber=>1, :number=>2, :songid=>song.id}])
    tracks =  @album.tracks
    tracks.must_equal [Track.load(:discnumber=>1, :number=>2, :songid=>song.id)]
    @album.tracks.must_equal(tracks)
    tracks.first.associations[:song].must_equal song
  end

  specify "#create_tracklist should raise an error if the album already has a tracklist" do
    @album.create_tracklist("Track1\nTrack2")
    proc{@album.create_tracklist("Track1\nTrack2")}.must_raise Sequel::Error
  end

  specify "#create_tracklist should create tracks from an input string" do
    @album.create_tracklist("Track1\nTrack2")
    Discname.count.must_equal 0
    songs = Song.order(:name).all
    songs.length.must_equal 2
    songs.first[:name].must_equal 'Track1'
    songs.last[:name].must_equal 'Track2'
    @album.refresh.tracks.must_equal [Track.load(:discnumber=>1, :number=>1, :songid=>songs.first.id), Track.load(:discnumber=>1, :number=>2, :songid=>songs.last.id)]
  end

  specify "#create_tracklist should create discs and tracks from an input string with blank lines" do
    @album.create_tracklist("Track1\n\nTrack2")
    discs = Discname.all
    discs.length.must_equal 2
    discs.first.to_hash.values_at(:number, :name, :albumid).must_equal [1, 'Disc 1', @album.id]
    discs.last.to_hash.values_at(:number, :name, :albumid).must_equal [2, 'Disc 2', @album.id]
    songs = Song.order(:name).all
    songs.length.must_equal 2
    songs.first[:name].must_equal 'Track1'
    songs.last[:name].must_equal 'Track2'
    @album.refresh.tracks.must_equal [Track.load(:discnumber=>1, :number=>1, :songid=>songs.first.id), Track.load(:discnumber=>2, :number=>1, :songid=>songs.last.id)]
  end

  specify "#create_tracklist should use existing songs instead of creating new ones" do
    s1 = Song.create(:name=>'Track1')
    s2 = Song.create(:name=>'Track2')
    @album.create_tracklist("Track1\nTrack2")
    Song.order(:name).all.must_equal [s1, s2]
    @album.refresh.tracks.must_equal [Track.load(:discnumber=>1, :number=>1, :songid=>s1.id), Track.load(:discnumber=>1, :number=>2, :songid=>s2.id)]
  end

  specify "#create_tracklist should escape & and \"" do
    @album.create_tracklist("Tr&ck1\nTr\"ck2")
    Discname.count.must_equal 0
    songs = Song.order(:name).all
    songs.length.must_equal 2
    songs.first[:name].must_equal 'Tr&amp;ck1'
    songs.last[:name].must_equal 'Tr&quot;ck2'
    @album.refresh.tracks.must_equal [Track.load(:discnumber=>1, :number=>1, :songid=>songs.first.id), Track.load(:discnumber=>1, :number=>2, :songid=>songs.last.id)]
  end

  specify "#create_tracklist should handle CRLF" do
    @album.create_tracklist("Track1\r\nTrack2\r\n\r\nTrack3")
    discs = Discname.all
    discs.length.must_equal 2
    discs.first.to_hash.values_at(:number, :name, :albumid).must_equal [1, 'Disc 1', @album.id]
    discs.last.to_hash.values_at(:number, :name, :albumid).must_equal [2, 'Disc 2', @album.id]
    songs = Song.order(:name).all
    songs.length.must_equal 3
    songs[0][:name].must_equal 'Track1'
    songs[1][:name].must_equal 'Track2'
    songs[2][:name].must_equal 'Track3'
    @album.refresh.tracks.must_equal [Track.load(:discnumber=>1, :number=>1, :songid=>songs[0].id), Track.load(:discnumber=>1, :number=>2, :songid=>songs[1].id), Track.load(:discnumber=>2, :number=>1, :songid=>songs[2].id)]
  end

  specify "#create_tracklist should an arbitrary number of blank lines" do
    @album.create_tracklist("Track1\n\n\n\nTrack2")
    discs = Discname.all
    discs.length.must_equal 2
    discs.first.to_hash.values_at(:number, :name, :albumid).must_equal [1, 'Disc 1', @album.id]
    discs.last.to_hash.values_at(:number, :name, :albumid).must_equal [2, 'Disc 2', @album.id]
    songs = Song.order(:name).all
    songs.length.must_equal 2
    songs.first[:name].must_equal 'Track1'
    songs.last[:name].must_equal 'Track2'
    @album.refresh.tracks.must_equal [Track.load(:discnumber=>1, :number=>1, :songid=>songs.first.id), Track.load(:discnumber=>2, :number=>1, :songid=>songs.last.id)]
  end

  specify "#update_tracklist_game should update the game for the songs in the given range in the tracklist" do
    s1 = Song.create(:name=>'Track1')
    s2 = Song.create(:name=>'Track2')
    @album.create_tracklist("Track1\nTrack2")

    g = Game.create(:name=>'Game')
    @album.update_tracklist_game(1, 1, 1, g.id)
    s1.refresh.gameid.must_equal g.id
    s2.refresh.gameid.must_be_nil

    g2 = Game.create(:name=>'Game')
    @album.update_tracklist_game(1, 2, 2, g2.id)
    s1.refresh.gameid.must_equal g.id
    s2.refresh.gameid.must_equal g2.id

    g3 = Game.create(:name=>'Game')
    @album.update_tracklist_game(1, 1, 2, g3.id)
    s1.refresh.gameid.must_equal g3.id
    s2.refresh.gameid.must_equal g3.id
  end
end

describe Albuminfo do
  before do
    @info = Albuminfo.create(:discnumber=>1, :starttrack=>2, :endtrack=>4, :info=>'Bonus')
  end

  specify "associations be correct" do
    @info.album.must_be_nil
  end
end

describe Artist do
  before do
    @artist = Artist.create(:name=>'blah')
  end

  specify "associations should be correct" do
    lyric1 = Lyric.create
    Song.create(:lyricid=>lyric1.id)
    lyric2 = Lyric.create(:composer_id=>@artist.id)
    song2 = Song.create(:name=>'Z', :lyricid=>lyric2.id)
    lyric3 = Lyric.create(:lyricist_id=>@artist.id)
    song3 = Song.create(:name=>'Y', :lyricid=>lyric3.id)
    @artist.songs.must_equal [song3, song2]
    Artist.eager(:songs).all.first.songs.must_equal [song3, song2]
  end
end

describe Discname do
  before do
    @disc = Discname.create
  end

  specify "associations be correct" do
    @disc.album.must_be_nil
  end
end

describe Game do
  before do
    @game = Game.create
  end

  specify "associations be correct" do
    @game.series.must_be_nil
    @game.songs.must_equal []
    @game.albums.must_equal []
  end
end

describe Lyric do
  before do
    @lyric = Lyric.create
  end

  specify "associations be correct" do
    @lyric.song.must_be_nil
    @lyric.lyric_verses.must_equal []
    @lyric.english_verses.must_equal []
    @lyric.romaji_verses.must_equal []
    @lyric.japanese_verses.must_equal []
    @lyric.composer.must_be_nil
    @lyric.arranger.must_be_nil
    @lyric.vocalist.must_be_nil
    @lyric.lyricist.must_be_nil
  end

  specify "#has_japanese_verses? should return whether there are any japanese verses" do
    @lyric.has_japanese_verses?.must_equal false
    LyricVerse.create(:lyricsongid=>@lyric.id, :languageid=>3)
    @lyric.refresh
    @lyric.has_japanese_verses?.must_equal true
  end

  specify "#japanese_title should be the songs japanese title, game, and original name" do
    @lyric.jsongname = 'X'
    @lyric.song = Song.create(:name=>'X')
    if RUBY_VERSION >= '1.9'
      @lyric.japanese_title.must_equal "X \uFF08\u300C\u300D\uFF09"
      @lyric.joriginalsongname = 'Y'
      @lyric.japanese_title.must_equal "X \uFF08\u300CY\u300D\uFF09"
      @lyric.song.game = Game.create(:jname=>'Z')
      @lyric.japanese_title.must_equal "X \uFF08Z\u300CY\u300D\uFF09"
    else
      @lyric.japanese_title.must_equal "X \357\274\210\343\200\214\343\200\215\357\274\211"
      @lyric.joriginalsongname = 'Y'
      @lyric.japanese_title.must_equal "X \357\274\210\343\200\214Y\343\200\215\357\274\211"
      @lyric.song.game = Game.create(:jname=>'Z')
      @lyric.japanese_title.must_equal "X \357\274\210Z\343\200\214Y\343\200\215\357\274\211"
    end
  end
  
  specify "#title should be the songs title, game, and original name" do
    @lyric.song = Song.create(:name=>'X')
    @lyric.title.must_equal 'X ()'
    @lyric.song.game = Game.create(:name=>'Z')
    @lyric.title.must_equal 'X (Z)'
    @lyric.song.arrangement = Song.create(:name=>'T')
    @lyric.title.must_equal 'X (Z - T)'
  end
end

describe LyricVerse do
  before do
    @verse = LyricVerse.create
  end

  specify "associations be correct" do
    @verse.lyric.must_be_nil
  end
end

describe Mediatype do
  before do
    @mtype = Mediatype.create
  end
  after do
    Mediatype.dataset.delete
  end

  specify "associations be correct" do
    @mtype.media.must_equal []
  end
end

describe Medium do
  before do
    @album = Album.create(:fullname=>'Blah')
    @album2 = Album.create(:fullname=>'Boh')
    @mtype = Mediatype.create(:name=>'CD')
    @mtype2 = Mediatype.create(:name=>'DVD')
    @medium = Medium.create(:mediatype=>@mtype, :price=>900, :publicationdate=>'1999-10-31', :album=>@album)
    @medium2 = Medium.create(:mediatype=>@mtype2, :publicationdate=>'2000-11-23', :album=>@album2)
  end

  specify "associations be correct" do
    @medium.album.must_equal @album
    @medium.mediatype.must_equal @mtype
    @medium.publisher.must_be_nil
  end

  specify ".find_albums_by_date should return an array of arrays of date, album, and year" do
    Medium.find_albums_by_date.must_equal [[Date.parse('2000-11-23'), @album2, 2000], [Date.parse('1999-10-31'), @album, 1999]]
  end

  specify ".find_albums_by_date should filter to the given year if provided " do
    Medium.find_albums_by_date(2000).must_equal [[Date.parse('2000-11-23'), @album2, 2000]]
  end

  specify ".find_albums_by_mediatype should return an array of arrays of nil, album, and mediatype name" do
    Medium.find_albums_by_mediatype.must_equal [[nil, @album, 'CD'], [nil, @album2, 'DVD']]
  end

  specify ".find_albums_by_mediatype should filter to the given mediatype if provided" do
    Medium.find_albums_by_mediatype(@mtype.id).must_equal [[nil, @album, 'CD']]
  end

  specify ".find_albums_by_price should return an array of arrays of nil, album, and price" do
    Medium.find_albums_by_price.must_equal [[nil, @album2, 'Not for Sale'], [nil, @album, '900 Yen']]
  end

  specify ".find_albums_by_price should filter to the given price if provided" do
    Medium.find_albums_by_price(900).must_equal [[nil, @album, '900 Yen']]
  end

  specify ".find_albums_by_price should filter for nil price if given a 0" do
    Medium.find_albums_by_price(0).must_equal [[nil, @album2, 'Not for Sale']]
  end

  specify "#price should be a string giving the price" do
    @medium.price.must_equal '900 Yen'
    @medium2.price.must_equal 'Not for Sale'
  end

  specify "#priceid should be a number giving the price, or 0 for nil price" do
    @medium.priceid.must_equal 900
    @medium2.priceid.must_equal 0
  end
end

describe Publisher do
  before do
    @pub = Publisher.create
    @album = Album.create(:fullname=>'Boh')
    @medium = Medium.create(:publisher=>@pub, :price=>900, :publicationdate=>'1999-10-31', :album=>@album)
  end

  specify "associations be correct" do
    @pub.media.must_equal [@medium]
    @pub.albums.must_equal [@album]
    Publisher.eager(:albums).all.first.albums.must_equal [@album]
  end
end

describe Series do
  before do
    @series = Series.create
  end

  specify "associations be correct" do
    @series.albums.must_equal []
    @series.games.must_equal []
  end
end

describe Song do
  before do
    @song = Song.create(:name=>'S')
  end

  specify "associations be correct" do
    @song.arrangements.must_equal []
    @song.game.must_be_nil
    @song.lyric.must_be_nil
    @song.arrangement.must_be_nil
  end

  specify "#tracks should be an array of tracks associated to the song, with an associated album" do
    @song.tracks.must_equal []
    album = Album.create(:fullname=>'A')
    album.create_tracklist("S")
    album.tracks.first.song.must_equal @song
    Song.first.tracks.must_equal album.tracks
  end
end

describe Track do
  before do
    @album = Album.create(:fullname=>'Blah', :numdiscs=>2)
    @song = Song.create(:name=>'Song')
    @track = Track.create(:number=>10, :discnumber=>2, :album=>@album, :song=>@song)
  end

  specify "associations be correct" do
    @track.song(:reload=>true).must_equal @song
  end

  specify "#album_and_number should give the album, number, and discnumber (if numdiscs is > 1)" do
    @track.album = @album
    @track.album_and_number.must_equal 'Blah, Disc 2, Track 10'
    @track.album.numdiscs = 1
    @track.album_and_number.must_equal 'Blah, Track 10'
  end
end
