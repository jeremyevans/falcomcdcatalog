# encoding: BINARY

require 'capybara'
require 'capybara/dsl'
require 'rack/test'
require 'rack/mock'

require_relative 'test_helper'
Gem.suffix_pattern

require_relative 'falcomcdcatalog'

Falcom::App.not_found{raise "path not found: #{request.path_info}"}
Falcom::App.error{|e| raise e}
Falcom::App.freeze

Capybara.app = Falcom::App.app
Capybara.exact = true
Capybara.ignore_hidden_elements = false

begin
  require 'refrigerator'
rescue LoadError
else
  Refrigerator.freeze_core(:except=>['BasicObject'])
end

class Minitest::Spec
  include Rack::Test::Methods
  include Capybara::DSL

  after do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

describe 'falcomcdcatalog' do
  before(:all) do
    @series = Falcom::Series.create(:name=>'Ys')
    @game = Falcom::Game.create(:series=>@series, :name=>'Ys I', :jname=>'Ys IJ')
    @game2 = Falcom::Game.create(:series=>@series, :name=>'Ys II', :jname=>'Ys IIJ')
    @artist = Falcom::Artist.create(:name=>'Tomohiko Kishimoto', :jname=>'TK')
    @lyric = Falcom::Lyric.create(:jsongname=>'Endless HistoryJ', :rsongname=>'Endless History', :composer=>@artist, :arranger=>@artist, :lyricist=>@artist, :vocalist=>@artist, :joriginalsongname=>'Too Full With LoveJ'){|s| s.id = 1}
    @lyricverse = Falcom::LyricVerse.create(:lyric=>@lyric, :languageid=>1, :number=>1, :verse=>'Love you')
    @lyricverse2 = Falcom::LyricVerse.create(:lyric=>@lyric, :languageid=>1, :number=>2, :verse=>'So much')
    @lyricverse3 = Falcom::LyricVerse.create(:lyric=>@lyric, :languageid=>2, :number=>1, :verse=>'It Hurts')
    @lyricverse4 = Falcom::LyricVerse.create(:lyric=>@lyric, :languageid=>2, :number=>2, :verse=>'It Does')
    @lyricverse5 = Falcom::LyricVerse.create(:lyric=>@lyric, :languageid=>3, :number=>1, :verse=>'Over Soon')
    @lyricverse6 = Falcom::LyricVerse.create(:lyric=>@lyric, :languageid=>3, :number=>2, :verse=>'I hope')
    @song = Falcom::Song.create(:name=>'Too Full With Love', :game=>@game){|s| s.id = 1}
    @song2 = Falcom::Song.create(:name=>'Endless History', :game=>@game, :lyric=>@lyric, :arrangement=>@song){|s| s.id = 2}
    @album = Falcom::Album.create(:fullname=>'Ys OST', :sortname=>'Ys  OST', :numdiscs=>1, :tracks=>[Falcom::Track.new(:discnumber=>1, :number=>1, :songid=>@song.id)], :picture=>'abcd.jpg'){|s| s.id = 1}
    @album2 = Falcom::Album.create(:fullname=>'Ys II OST', :sortname=>'Ys 2 OST'){|s| s.id = 2}
    @album3 = Falcom::Album.create(:fullname=>'The Legend of Heroes OST', :sortname=>'Legend of Heroes OST'){|s| s.id = 3}
    @info = Falcom::Albuminfo.create(:album=>@album, :discnumber=>1, :starttrack=>1, :endtrack=>1, :info=>'Special Vocal')
    @discname = Falcom::Discname.create(:album=>@album, :number=>1, :name=>'Special Disc')
    @mediatype = Falcom::Mediatype.create(:name=>'CD')
    @mediatype2 = Falcom::Mediatype.create(:name=>'Vinyl')
    @publisher = Falcom::Publisher.create(:name=>'Nihon Falcom')
    @publisher2 = Falcom::Publisher.create(:name=>'Konami')
    @medium = Falcom::Medium.create(:album=>@album, :mediatype=>@mediatype, :catalognumber=>'KICA-0001', :price=>1000, :publicationdate=>Date.new(2000), :ordernum=>1.0, :publisher=>@publisher)
    @medium2 = Falcom::Medium.create(:album=>@album, :mediatype=>@mediatype2, :catalognumber=>'KICA-0002', :publicationdate=>Date.new(2000), :ordernum=>2.0, :publisher=>@publisher)
    @medium3 = Falcom::Medium.create(:album=>@album2, :mediatype=>@mediatype, :catalognumber=>'KICA-0003', :price=>10000, :publicationdate=>Date.new(2001), :ordernum=>1.0, :publisher=>@publisher2)

    @album.add_game(@game)
    @album2.add_series(@series)
  end

  before do
    visit '/'
  end

  it "should have working index and info pages" do
    page.title.must_equal 'Falcom CD Catalog - English Edition'

    click_link 'Site News'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Site News'

    click_link 'Site Information'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Site Information'

    click_link 'Falcom Ordering Information'
    page.title.must_equal 'Falcom CD Catalog - English Edition - How to Order Albums from Falcom'

    visit '/'
    click_link 'Old Site (2003-2005)'
    page.body.must_include 'If you are still interested in the old site, you can find it archived'
    click_link 'here'
    page.title.must_equal 'Falcom Discography - English Edition'
  end

  it "should provide album pages" do
    click_link 'Albums By Date'
    click_link 'Ys OST'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Ys OST'
    page.all('#tracklist h2').map(&:text).must_equal ["Special Disc (Edit)"]
    page.all('#tracklist h4').map(&:text).must_equal ["Special Vocal (Edit)"]
    page.all('#tracklist li a').map(&:text).must_equal ["Too Full With Love"]
    page.all('#tracklist h2').map(&:text).must_equal ["Special Disc (Edit)"]
    page.all('#albuminfo li').map(&:text).must_equal ["CD: KICA-0001 (1000 Yen) [Nihon Falcom 2000-01-01] (Edit)", "Vinyl: KICA-0002 (Not for Sale) [Nihon Falcom 2000-01-01] (Edit)", "Edit Album", "Add Release", "Add Album Info", "View Tracklist Table"]
  end

  it "should provide a list of albums by date" do
    click_link 'Albums By Date'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums By Release Date'
    page.all('h2').map(&:text).must_equal ["2001", "2000"]
    page.all('#content li').map(&:text).must_equal ["2001-01-01 - Ys II OST", "2000-01-01 - Ys OST"]
    page.all('#content li a').map(&:text).must_equal ["Ys II OST", "Ys OST"]

    click_link 'Ys OST'
    click_link '2000', match: :first
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums Released in 2000'
    page.all('#content li').map(&:text).must_equal ["2000-01-01 - Ys OST"]
    page.all('#content li a').map(&:text).must_equal ["Ys OST"]
  end

  it "should provide a list of albums by media type" do
    click_link 'Albums By Media Type'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums By Media Type'
    page.all('h2').map(&:text).must_equal ["CD", "Vinyl"]
    page.all('#content li').map(&:text).must_equal ["Ys OST", "Ys II OST", "Ys OST"]
    page.all('#content li a').map(&:text).must_equal ["Ys OST", "Ys II OST", "Ys OST"]

    click_link 'Ys OST', match: :first
    click_link 'Vinyl'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums in Vinyl format'
    page.all('#content li').map(&:text).must_equal ["Ys OST"]
    page.all('#content li a').map(&:text).must_equal ["Ys OST"]
  end

  it "should provide a list of albums by name" do
    click_link 'Albums By Name'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums By Name'
    page.all('h2').map(&:text).must_equal ["L", "Y"]
    page.all('#content li').map(&:text).must_equal ["The Legend of Heroes OST", "Ys OST", "Ys II OST"]
    page.all('#content li a').map(&:text).must_equal ["The Legend of Heroes OST", "Ys OST", "Ys II OST"]

    visit("/albums_by_name/L")
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums Starting with L'
    page.all('#content li').map(&:text).must_equal ["The Legend of Heroes OST"]
    page.all('#content li a').map(&:text).must_equal ["The Legend of Heroes OST"]
  end

  it "should provide a list of albums by price" do
    click_link 'Albums By Price'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums By Price'
    page.all('h2').map(&:text).must_equal ["Not for Sale", "1000 Yen", "10000 Yen"]
    page.all('#content li').map(&:text).must_equal ["Ys OST", "Ys OST", "Ys II OST"]
    page.all('#content li a').map(&:text).must_equal ["Ys OST", "Ys OST", "Ys II OST"]

    click_link 'Ys OST', match: :first
    click_link 'Not for Sale'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums Not for Sale'
    page.all('#content li').map(&:text).must_equal ["Ys OST"]
    page.all('#content li a').map(&:text).must_equal ["Ys OST"]

    click_link 'Ys OST'
    click_link '1000 Yen'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums Costing 1000 Yen'
    page.all('#content li').map(&:text).must_equal ["Ys OST"]
    page.all('#content li a').map(&:text).must_equal ["Ys OST"]
  end

  it "should provide an album photoboard" do
    click_link 'Album Photoboard'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Album Photoboard'
    page.all('#content img').map{|e| e[:src]}.must_equal ["/images/abcd.jpg"]
    page.first('#content a').click
    page.title.must_equal 'Falcom CD Catalog - English Edition - Ys OST'
  end

  it "should provide a list of artists" do
    click_link 'Artists'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Artists'
    page.all('#content li a').map(&:text).must_equal ["Tomohiko Kishimoto"]
    click_link 'Tomohiko Kishimoto'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Songs Worked On By Tomohiko Kishimoto'
    page.all('#content li a').map(&:text).must_equal ["Endless History"]
    click_link 'Endless History'
    page.title.must_equal "Falcom CD Catalog - English Edition - Endless History (Ys I - Too Full With Love)"
  end

  it "should provide a list of games" do
    click_link 'Games'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Games'
    page.all('#content li a').map(&:text).must_equal ["Ys I", 'Ys II']
    click_link 'Ys I'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Ys I'
    page.all('#content li a').map(&:text).must_equal ['Ys OST', "Endless History", "Too Full With Love"]
    click_link 'Ys OST'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Ys OST'
  end

  it "should provide a list of publishers" do
    click_link 'Publishers'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Publishers'
    page.all('#content li a').map(&:text).must_equal ['Konami', "Nihon Falcom"]
    click_link 'Nihon Falcom'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums Published By Nihon Falcom'
    page.all('#content li a').map(&:text).must_equal ['Ys OST']
    click_link 'Ys OST'
    click_link 'Nihon Falcom', match: :first
    page.title.must_equal 'Falcom CD Catalog - English Edition - Albums Published By Nihon Falcom'
  end

  it "should provide a list of series" do
    click_link 'Series'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Series'
    page.all('#content li a').map(&:text).must_equal ["Ys"]
    click_link 'Ys'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Ys Albums'
    page.all('#content h2 a').map(&:text).must_equal ["Ys I"]
    page.all('#content li a').map(&:text).must_equal ["Ys OST", "Ys II OST"]
    click_link 'Ys II OST'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Ys II OST'

    click_link 'Series'
    click_link 'Ys'
    click_link 'Ys OST'
    page.title.must_equal 'Falcom CD Catalog - English Edition - Ys OST'
  end

  it "should provide a random album" do
    click_link 'Random Album'
    [@album, @album2, @album3].map(&:fullname).must_include page.first('h1').text
  end

  it "should provide a random lyric" do
    click_link 'Random Lyric'
    page.title.must_equal "Falcom CD Catalog - English Edition - Endless History (Ys I - Too Full With Love)"
  end

  it "should provide a random song" do
    click_link 'Random Song'
    [@song, @song2].map(&:name).must_include page.first('h1').text
  end

  it "should allow searching for songs" do
    fill_in 'songname', with: 'too full'
    click_button 'song-search-submit' 
    page.title.must_equal "Falcom CD Catalog - English Edition - Song Search Results"
    page.first('h4').text.must_equal '1 Matches'
    page.all('#content li').map(&:text).must_equal ["Too Full With Love"]
  end

  it "should allow resetting a tracklist for an album" do
    click_link 'Albums By Name'
    click_link 'Ys OST'
    click_link 'View Tracklist Table'
    page.title.must_equal "Falcom CD Catalog - English Edition - Tracklist for Ys OST"
    page.all('#content td').map(&:text).must_equal ["1", "1", "Too Full With Love", "Ys I", ""]
    fill_in 'Disc', :with=>'1'
    fill_in 'Start', :with=>'1'
    fill_in 'End', :with=>'1'
    select 'Ys II'
    click_button 'Assign to Game'
    page.all('#content td').map(&:text).must_equal ["1", "1", "Too Full With Love", "Ys II", ""]
  end

  it "should provide lyric pages" do
    click_link 'Albums By Name'
    click_link 'Ys OST'
    click_link 'Too Full With Love'
    click_link 'Ys OST, Track 1'
    click_link 'Too Full With Love'
    click_link 'Endless History'
    click_link 'Lyrics'
    page.title.must_equal "Falcom CD Catalog - English Edition - Endless History (Ys I - Too Full With Love)"
    page.first('#content p').text.must_equal 'Music: Tomohiko Kishimoto Arrangement: Tomohiko Kishimoto Lyric: Tomohiko Kishimoto Vocal: Tomohiko Kishimoto'
    page.all('.lyric').map(&:text).must_equal ["Love you", "So much"]
    page.all('.lyric-romaji').map(&:text).must_equal ["It Hurts", "It Does"]

    click_link 'Japanese Lyrics'
    page.title.force_encoding('BINARY').must_equal "Falcom CD Catalog - English Edition - Endless HistoryJ \xEF\xBC\x88Ys IJ\xE3\x80\x8CToo Full With LoveJ\xE3\x80\x8D\xEF\xBC\x89".force_encoding('BINARY')
    page.first('#content p').text.must_equal 'Music: TK Arrangement: TK Lyric: TK Vocal: TK'
    page.all('.lyric-verse').map(&:text).must_equal ["Over Soon", "I hope"]
  end

  it "should support adding new tracklists" do
    click_link 'Albums By Name'
    click_link 'Ys II OST'
    click_link 'Add Tracklist'
    page.title.must_equal "Falcom CD Catalog - English Edition - Add tracklist for Ys II OST"
    fill_in 'tracklist', with: "Foo\nBar"
    click_button 'Add Tracklist'
    page.all('#tracklist li').map(&:text).must_equal ["Foo", "Bar"]
  end

  it "should support album editing" do
    click_link 'Albums By Name'
    click_link 'Ys OST'
    elements = page.all('#content a').select{|e| e.text == '(Edit)'}
    elements[0].click
    page.title.must_equal "Falcom CD Catalog - English Edition - Medium - Edit"

    click_link 'Albums By Name'
    click_link 'Ys OST'
    elements = page.all('#content a').select{|e| e.text == '(Edit)'}
    elements[1].click
    page.title.must_equal "Falcom CD Catalog - English Edition - Medium - Edit"

    click_link 'Albums By Name'
    click_link 'Ys OST'
    elements = page.all('#content a').select{|e| e.text == '(Edit)'}
    elements[2].click
    page.title.must_equal "Falcom CD Catalog - English Edition - Discname - Edit"

    click_link 'Albums By Name'
    click_link 'Ys OST'
    elements = page.all('#content a').select{|e| e.text == '(Edit)'}
    elements[3].click
    page.title.must_equal "Falcom CD Catalog - English Edition - Albuminfo - Edit"

    click_link 'Albums By Name'
    click_link 'Ys OST'
    click_link 'Edit Album'
    page.title.must_equal "Falcom CD Catalog - English Edition - Album - Edit"

    click_link 'Albums By Name'
    click_link 'Ys OST'
    click_link 'Add Release'
    page.title.must_equal "Falcom CD Catalog - English Edition - Medium - New"

    click_link 'Albums By Name'
    click_link 'Ys OST'
    click_link 'Add Album Info'
    page.title.must_equal "Falcom CD Catalog - English Edition - Albuminfo - New"
  end

  it "should support management" do
    click_link 'Manage Album'   
    select 'Ys OST'
    click_button 'Edit'

    @album.games_dataset.select_order_map(:id).must_equal [@game.id]
    page.find('form[data-add="#add_games"] input[type=submit]').click
    @album.games_dataset.select_order_map(:id).must_equal []
    select 'Ys II'
    page.find('form[data-remove="#games_remove_list"] input[type=submit]').click
    @album.games_dataset.select_order_map(:id).must_equal [@game2.id]

    @album.series_dataset.select_order_map(:id).must_equal []
    select 'Ys'
    page.find('form[data-remove="#series_remove_list"] input[type=submit]').click
    @album.series_dataset.select_order_map(:id).must_equal [@series.id]
    page.find('form[data-add="#add_series"] input[type=submit]').click
    @album.series_dataset.select_order_map(:id).must_equal []

    click_link 'Manage Game'   
    select 'Ys II'
    click_button 'Edit'

    @game2.albums_dataset.select_order_map(:id).must_equal [@album.id]
    page.find('form[data-add="#add_albums"] input[type=submit]').click
    @game2.albums_dataset.select_order_map(:id).must_equal []
    select 'Ys II OST'
    page.find('form[data-remove="#albums_remove_list"] input[type=submit]').click
    @game2.albums_dataset.select_order_map(:id).must_equal [@album2.id]

    click_link 'Manage Series'   
    select 'Ys'
    click_button 'Edit'

    @series.albums_dataset.select_order_map(:id).must_equal [@album2.id]
    page.find('form[data-add="#add_albums"] input[type=submit]').click
    @series.albums_dataset.select_order_map(:id).must_equal []
    select 'Ys OST'
    page.find('form[data-remove="#albums_remove_list"] input[type=submit]').click
    @series.albums_dataset.select_order_map(:id).must_equal [@album.id]
  end if ENV['FALCOMCDS_ADMIN']
end
