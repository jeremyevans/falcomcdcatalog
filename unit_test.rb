#!/usr/local/bin/spec
require 'rubygems'
$:.unshift('/home/jeremy/sequel/lib')
require 'sequel'
DB = Sequel.postgres('falcomcdcatalog_test', :user=>'_postgresql', :host=>'/tmp')
Dir['models/*.rb'].each{|f| require(f)}
[:albuminfos, :tracks, :discnames, :media, :mediatypes, :publishers, :tracks, :lyricverses, :lyricsongs, :songs, :games, :series, :artists, :albums].each{|x| DB[x].delete}

describe Album do
  before do
    @album = Album.create(:fullname=>'A TestAlbum', :sortname=>'TestAlbum')
    @album2 = Album.create(:fullname=>'OtherAlbum', :sortname=>'OtherAlbum')
  end
  after do
    Album.delete
  end

  specify "associations be correct" do
    @album.tracks.should == []
    @album.discnames.should == []
    @album.albuminfos.should == []
    @album.media.should == []
    @album.games.should == []
    @album.series.should == []
  end

  specify ".group_all_by_sortname should give an array of arrays of nil, albums, and initals" do
    Album.group_all_by_sortname.should == [[nil, @album2, 'O'], [nil, @album, 'T']]
  end

  specify ".group_all_by_sortname should filter by initial if given an inital" do
    Album.group_all_by_sortname('T').should == [[nil, @album, 'T']]
  end

  specify "#scaffold_name should be the alias of fullname" do
    @album.scaffold_name.should == 'A TestAlbum'
  end

  specify "#<=> should go by sortname" do
    [@album, @album2].sort.should == [@album2, @album]
  end
end

describe Albuminfo do
  before do
    @info = Albuminfo.create(:discnumber=>1, :starttrack=>2, :endtrack=>4, :info=>'Bonus')
  end
  after do
    Albuminfo.delete
  end

  specify "associations be correct" do
    @info.album.should == nil
  end

  specify "#scaffold_name should be correct" do
    @info.scaffold_name.should == '1-2-4-Bonus'
  end
end

describe Artist do
  before do
    @artist = Artist.create(:name=>'blah')
  end
  after do
    Song.delete
    Lyric.delete
    Artist.delete
  end

  specify "associations should be correct" do
    lyric1 = Lyric.create
    song1 = Song.create(:lyricid=>lyric1.id)
    lyric2 = Lyric.create(:composer_id=>@artist.id)
    song2 = Song.create(:name=>'Z', :lyricid=>lyric2.id)
    lyric3 = Lyric.create(:lyricist_id=>@artist.id)
    song3 = Song.create(:name=>'Y', :lyricid=>lyric3.id)
    @artist.songs.should == [song3, song2]
    Artist.eager(:songs).all.first.songs.should == [song3, song2]
  end
end

describe Discname do
  before do
    @disc = Discname.create
  end
  after do
    Discname.delete
  end

  specify "associations be correct" do
    @disc.album.should == nil
  end
end

describe Game do
  before do
    @game = Game.create
  end
  after do
    Game.delete
  end

  specify "associations be correct" do
    @game.series.should == nil
    @game.songs.should == []
    @game.albums.should == []
  end
end

describe Lyric do
  before do
    @lyric = Lyric.create
  end
  after do
    Song.delete
    Game.delete
    LyricVerse.delete
    Lyric.delete
  end

  specify "associations be correct" do
    @lyric.song.should == nil
    @lyric.lyric_verses.should == []
    @lyric.english_verses.should == []
    @lyric.romaji_verses.should == []
    @lyric.japanese_verses.should == []
    @lyric.composer.should == nil
    @lyric.arranger.should == nil
    @lyric.vocalist.should == nil
    @lyric.lyricist.should == nil
  end

  specify "#scaffold_name should be the song's name" do
    @lyric.song = Song.create(:name=>'Blah')
    @lyric.scaffold_name == 'Blah'
  end

  specify "#has_japanese_verses? should return whether there are any japanese verses" do
    @lyric.has_japanese_verses?.should == false
    LyricVerse.create(:lyricsongid=>@lyric.id, :languageid=>3)
    @lyric.refresh
    @lyric.has_japanese_verses?.should == true
  end

  specify "#japanese_title should be the songs japanese title, game, and original name" do
    @lyric.jsongname = 'X'
    @lyric.song = Song.create(:name=>'X')
    @lyric.japanese_title.should == "X \357\274\210\343\200\214\343\200\215\357\274\211"
    @lyric.joriginalsongname = 'Y'
    @lyric.japanese_title.should == "X \357\274\210\343\200\214Y\343\200\215\357\274\211"
    @lyric.song.game = Game.create(:jname=>'Z')
    @lyric.japanese_title.should == "X \357\274\210Z\343\200\214Y\343\200\215\357\274\211"
  end
  
  specify "#title should be the songs title, game, and original name" do
    @lyric.song = Song.create(:name=>'X')
    @lyric.title.should == 'X ()'
    @lyric.song.game = Game.create(:name=>'Z')
    @lyric.title.should == 'X (Z)'
    @lyric.song.arrangement = Song.create(:name=>'T')
    @lyric.title.should == 'X (Z - T)'
  end
end

describe LyricVerse do
  before do
    @verse = LyricVerse.create
  end
  after do
    LyricVerse.delete
  end

  specify "associations be correct" do
    @verse.lyric.should == nil
  end

  specify "#scaffold_name should be correct" do
    @verse.set(:verse => '1234567890' * 5, :number=>3)
    @verse.scaffold_name.should == "Verse 3 - #{'1234567890' * 4}"
    @verse.languageid = 3
    @verse.scaffold_name.should == "Verse 3 - Japanese text"
  end
end

describe Mediatype do
  before do
    @mtype = Mediatype.create
  end
  after do
    Mediatype.delete
  end

  specify "associations be correct" do
    @mtype.media.should == []
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
  after do
    Medium.delete
    Mediatype.delete
    Album.delete
  end

  specify "associations be correct" do
    @medium.album.should == @album
    @medium.mediatype.should == @mtype
    @medium.publisher.should == nil
  end

  specify ".find_albums_by_date should return an array of arrays of date, album, and year" do
    Medium.find_albums_by_date.should == [['2000-11-23'.to_date, @album2, 2000], ['1999-10-31'.to_date, @album, 1999]]
  end

  specify ".find_albums_by_date should filter to the given year if provided " do
    Medium.find_albums_by_date(2000).should == [['2000-11-23'.to_date, @album2, 2000]]
  end

  specify ".find_albums_by_mediatype should return an array of arrays of nil, album, and mediatype name" do
    Medium.find_albums_by_mediatype.should == [[nil, @album, 'CD'], [nil, @album2, 'DVD']]
  end

  specify ".find_albums_by_mediatype should filter to the given mediatype if provided" do
    Medium.find_albums_by_mediatype(@mtype.id).should == [[nil, @album, 'CD']]
  end

  specify ".find_albums_by_price should return an array of arrays of nil, album, and price" do
    Medium.find_albums_by_price.should == [[nil, @album2, 'Not for Sale'], [nil, @album, '900 Yen']]
  end

  specify ".find_albums_by_price should filter to the given price if provided" do
    Medium.find_albums_by_price(900).should == [[nil, @album, '900 Yen']]
  end

  specify ".find_albums_by_price should filter for nil price if given a 0" do
    Medium.find_albums_by_price(0).should == [[nil, @album2, 'Not for Sale']]
  end

  specify "#price should be a string giving the price" do
    @medium.price.should == '900 Yen'
    @medium2.price.should == 'Not for Sale'
  end

  specify "#priceid should be a number giving the price, or 0 for nil price" do
    @medium.priceid.should == 900
    @medium2.priceid.should == 0
  end

  specify "#scaffold_name should be an alias of catalognumber" do
    @medium.scaffold_name.should == nil
    @medium.catalognumber = '1234-5678'
    @medium.scaffold_name.should == '1234-5678'
  end
end

describe Publisher do
  before do
    @pub = Publisher.create
    @album = Album.create(:fullname=>'Boh')
    @medium = Medium.create(:publisher=>@pub, :price=>900, :publicationdate=>'1999-10-31', :album=>@album)
  end
  after do
    Medium.delete
    Album.delete
    Publisher.delete
  end

  specify "associations be correct" do
    @pub.media.should == [@medium]
    @pub.albums.should == [@album]
    Publisher.eager(:albums).all.first.albums.should == [@album]
  end
end

describe Series do
  before do
    @series = Series.create
  end
  after do
    Series.delete
  end

  specify "associations be correct" do
    @series.albums.should == []
    @series.games.should == []
  end
end

describe Song do
  before do
    @song = Song.create
  end
  after do
    Song.delete
  end

  specify "associations be correct" do
    @song.tracks.should == []
    @song.arrangements.should == []
    @song.game.should == nil
    @song.lyric.should == nil
    @song.arrangement.should == nil
  end

  specify "#scaffold_name should be the first 51 characters of name" do
    @song.name = '1'*90
    @song.scaffold_name.should == '1'*51
  end
end

describe Track do
  before do
    @album = Album.create(:fullname=>'Blah', :numdiscs=>2)
    @song = Song.create(:name=>'Song')
    @track = Track.create(:number=>10, :discnumber=>2, :album=>@album, :song=>@song)
  end
  after do
    Track.delete
    Album.delete
    Song.delete
  end

  specify "associations be correct" do
    @track.song(true).should == @song
    @track.album(true).should == @album
  end

  specify "#album_and_number should give the album, number, and discnumber (if numdiscs is > 1)" do
    @track.album_and_number.should == 'Blah, Disc 2, Track 10'
    @track.album.numdiscs = 1
    @track.album_and_number.should == 'Blah, Track 10'
  end

  specify "#scaffold_name should give the album, discnumber, number, and song name" do
    @track.scaffold_name.should == 'Blah-2-10-Song'
  end
end
