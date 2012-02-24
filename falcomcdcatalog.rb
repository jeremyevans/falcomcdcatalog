#!/usr/bin/env ruby
#encoding: utf-8
require 'rubygems'
require 'erb'
require 'sinatra/base'
require 'cgi'
require 'models'
require 'rack/contrib'

# Disable caching in tilt in admin/development mode
if ADMIN
  class Tilt::Cache
    def fetch(*)
      yield
    end
  end
end

PUBLIC_ROOT = File.join(File.dirname(__FILE__), 'public')

class FalcomController < Sinatra::Base
  set(:appfile=>'falcomcdcatalog.rb', :default_encoding=>'UTF-8')
 
  def admin?
    ADMIN
  end
    
  def album_img(album, link=nil)
    img = "<img src=\"/images/#{album.picture}\" alt=\"#{h album.fullname}\" />"
    link ? link_to(img, link) : img
  end

  def albums_by_category
    @groups = []
    last_sep = nil
    @albums.each do |category, album, separator| 
      unless last_sep == separator
        @groups << [separator, []]
        last_sep = separator
      end
      @groups[-1][1] << [category, album]
    end
    erb :albums_by_category
  end

  def content_tag(tag, content)
    "<#{tag}>#{content}</#{tag}>"
  end
  
  def date_link(date)
    "#{link_to(date.year, "/albums_by_date/#{date.year}")}-#{'%02i' % date.month }-#{'%02i' % date.day}"
  end
  
  def h(text)
    CGI.escapeHTML(text.to_s)
  end

  def html_opts(hash)
    hash.map{|k,v| "#{k}=\"#{h(v)}\""}.join(' ')
  end

  def link_to(text, url)
    "<a href=\"#{url}\">#{text}</a>"
  end
  
  def mail_to_maintainer(text = nil)
    email = 'falcomcdcatalog@jeremyevans.net'
    link_to(text||email, "mailto:#{email}")
  end

  def model_select(name, objects, opts={})
    meth = opts.delete(:meth)||:name
    select(name, objects.map{|o| [o.send(meth), o.id]}, opts)
  end

  def select(name, options, opts={})
    "<select name=\"#{name}\" #{html_opts(opts)}>\n#{options.map{|t,v| "<option value=\"#{v}\">#{h(t)}</option>"}.join("\n")}\n</select>"
  end

  def song_link(song)
    link_to(song.name, "/song/#{song.id}")
  end
  
  def title(text)
    text.gsub(/<i>(.*?)<\/i>/m, '\1')
  end

  error do
    e = request.env['sinatra.error']
    puts e.message
    e.backtrace.each{|x| puts x}
    render(:erb, "<h3>Oops, an error occurred.</h3>")
  end

  not_found do
    render(:erb, "<h3>The page you are looking for does not exist.</h3>")
  end

  get "/" do
    erb :index
  end

  get %r{\A/(feedback|index|news|info|order)\z} do
    erb params[:captures][0].to_sym
  end

  get "/album/:id" do
    i = params[:id].to_i
    @album = Album[i]
    @discs = []
    @albuminfos = {}
    @album.discnames.length > 0 ? (@album.discnames.each{ |disc| @discs.push({:name=>disc.name, :tracks=>[], :id=>disc.id}) }) : @discs.push({:tracks=>[]})
    Track.filter(:albumid=>i).eager(:song).order(:tracks__discnumber, :tracks__number).all do |track|
      @discs[track.discnumber-1][:tracks].push track
    end
    @album.albuminfos.each {|info| (@albuminfos[[info.discnumber, info.starttrack]] ||= []) << info}
    @media = Medium.filter(:albumid=>i).order(:media__publicationdate).eager(:mediatype, :publisher)
    erb :album
  end

  get "/albums_by_date/?:id?" do
    year = params[:id].to_i if params[:id]
    @pagetitle = year ? "Albums Released in #{year}" : 'Albums By Release Date'
    @albums = Medium.find_albums_by_date(year)
    albums_by_category
  end

  get "/albums_by_media_type/?:id?" do
    mediatype = params[:id].to_i if params[:id]
    @albums = Medium.find_albums_by_mediatype(mediatype)
    @pagetitle = if !(mediatype and @albums.length > 0)
        'Albums By Media Type'
    else "Albums in #{@albums[0][2]} format"
    end
    albums_by_category
  end

  get "/albums_by_name/?:id?" do
    initial = params[:id][0...1] if params[:id]
    @albums = Album.group_all_by_sortname(initial)
    @pagetitle = if !(initial and @albums.length > 0)
        'Albums By Name'
    else "Albums Starting with #{initial}"
    end
    albums_by_category
  end
  
  get "/albums_by_price/?:id?" do
    price = params[:id].to_i if params[:id]
    @pagetitle = case price
      when nil then 'Albums By Price'
      when 0 then 'Albums Not for Sale'
      else "Albums Costing #{price} Yen"
    end
    @albums = Medium.find_albums_by_price(price)
    albums_by_category
  end

  get "/artists" do
    @artists = Artist.order(:name).all
    erb :artists
  end
  
  get "/artist/:id" do
    @artist = Artist[params[:id].to_i]
    erb :artist
  end
  
  get "/game/:id" do
    @game = Game[params[:id].to_i]
    erb :game
  end
  
  get "/games" do
    @games = Game.order(:name)
    erb :games
  end

  get "/japanese_lyric/:id" do
    @lyric = Lyric[params[:id].to_i]
    erb :japanese_lyric
  end

  get "/lyric/:id" do
    @lyric = Lyric[params[:id].to_i]
    erb :lyric
  end
  
  get "/photoboard" do
    @albums = Album.filter([[:picture, nil], [:picture, '']].sql_negate).order(:RANDOM.sql_function)
    erb :photoboard
  end

  get "/publisher/:id?" do
    @publisher = Publisher[params[:id].to_i]
    erb :publisher
  end
  
  get "/publishers" do
    @publishers = Publisher.order(:name)
    erb :publishers
  end
  
  get "/random_album" do
    redirect "/album/#{(rand(Album.count)+1)}"
  end
  
  get "/random_lyric" do
    redirect "/lyric/#{(rand(Lyric.count)+1)}"
  end
  
  get "/random_song" do
    redirect "/song/#{(rand(Song.count)+1)}"
  end
 
  get "/series/:id" do 
    i = params[:id].to_i
    @series = Series.eager_graph(:albums).order(:albums__fullname).filter(:series__id=>i).all.first
    @games = Game.eager_graph(:albums).order(:games__name, :albums__fullname).filter(:games__seriesid=>i).all
    erb :series
  end
  
  get "/series_list" do
    @series = Series.order(:name)
    erb :series_list
  end
  
  get "/song/:id?" do
    i = params[:id].to_i
    @song = Song[i]
    @tracks = Track.eager_graph(:album).order(:album__fullname, :tracks__discnumber, :tracks__number).filter(:tracks__songid=>i).all
    erb :song
  end
  
  get "/song_search_results" do
    @songs = Song.filter(:name.ilike("%#{params[:songname]}%")).order(:name).all
    erb :song_search_results
  end
  
  if ADMIN
    get "/new_tracklist/:id" do
      @album = Album[params[:id].to_i]
      redirect_to("/album/#{@album.id}")if @album.tracks.length > 0
      erb :new_tracklist
    end
  
    post "/create_tracklist/:id" do
      album = Album[params[:id].to_i]
      if album.tracks.length == 0  
        songs = {}
        Song.each{|s| songs[s.name.downcase.gsub(/\s/, "")] = s.id}
        disctracklists = params[:tracklist].strip.gsub("\r", "").split(/\n\n+/)
        DB.transaction do
          disctracklists.each_with_index do |tracklist, i| i+=1
            Discname.create(:albumid=>album.id, :number=>i, :name=>"Disc #{i}") if disctracklists.length > 1
            tracklist.split("\n").each_with_index do |track, j| j+=1
              track = track.strip.gsub('&', "&amp;").gsub('"', "&quot;")
              songid = track == '-' ? 1 : (songs[track.downcase.gsub(/\s/, "")] || (songs[track.downcase.gsub(/\s/, "")] = Song.create(:name=>track).id)) 
              Track.create(:albumid=>album.id, :discnumber=>i, :number=>j, :songid=>songid)
            end
          end
        end
      end
      redirect "/album/#{album.id}" 
    end

    get "/new_tracklist_table/:id" do
      @album = Album[params[:id].to_i]
      @games = Game.order(:name)
      @tracks = Track.select(:tracks__id, :tracks__discnumber, :tracks__number, :tracks__songid, :songs__name, :games__name___game, :arrangements__name___arrangement).left_outer_join(:songs, :id=>:songid).left_outer_join(:games, :id=>:gameid).left_outer_join(:songs, {:id=>:songs__arrangementof}, :arrangements).filter(:tracks__albumid => @album.id).order(:tracks__discnumber, :tracks__number)
      erb :new_tracklist_table
    end
  
    post "/update_tracklist_game/:id" do
      tracks = Track.filter(:albumid=>params[:id].to_i, :discnumber=>params[:disc].to_i, :number=>((params[:starttrack].to_i)..(params[:endtrack].to_i))).select(:songid)
      Song.filter(:id=>tracks).update(:gameid=>params[:game].to_i)
      redirect "/new_tracklist_table/#{params[:id]}"
    end
  
    post "/merge_update_artist" do
      from, to = params[:from].to_i, params[:to].to_i
      DB.transaction do
        [:composer_id, :arranger_id, :vocalist_id, :lyricist_id].each do |x|
          Lyric.filter(x=>from).update(x=>to)
        end
        Artist[from].destroy
      end
      redirect('/merge_artist')
    end

    require 'scaffolding_extensions'
    ScaffoldingExtensions.auto_complete_skip_style = true
    ScaffoldingExtensions.javascript_library = 'JQuery'
    ::ScaffoldingExtensions::MetaModel::SCAFFOLD_OPTIONS[:text_to_string] = true
    ::ScaffoldingExtensions::MetaModel::SCAFFOLD_OPTIONS[:auto_complete].merge!({:sql_name=>'name', :text_field_options=>{:size=>80}, :search_operator=>'ILIKE', :results_limit=>15, :phrase_modifier=>:to_s})
    ::ScaffoldingExtensions::MetaModel::SCAFFOLD_OPTIONS[:habtm_ajax] = true
    scaffold_all_models :only=>[Album, Albuminfo, Artist, Discname, Game, Lyric, LyricVerse, Mediatype, Medium, Publisher, Series, Song, Track]
  end
end

class FileServer
  def initialize(app, root)
    @app = app
    @rfile = Rack::File.new(root)
  end
  def call(env)
    res = @rfile.call(env)
    res[0] == 200 ? res : @app.call(env)
  end
end

Sequel::Model.plugin :identity_map
class SequelIdentityMap
  def initialize(app)
    @app = app
  end
  def call(env)
    Sequel::Model.with_identity_map{@app.call(env)}
  end
end

FALCOMCDCATALOG = Rack::Builder.app do
  use Rack::RelativeRedirect
  use FileServer, 'public'
  use SequelIdentityMap
  run FalcomController
end
