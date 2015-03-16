#!/usr/bin/env ruby
#encoding: utf-8
require 'rubygems'
require 'tilt/erubis'
require 'roda'
require './models'
require 'thamble'
require 'rack/indifferent'

PUBLIC_ROOT = File.join(File.dirname(__FILE__), 'public')

class FalcomController < Roda
  plugin :static, %w'/archive /favicon.ico /images /javascripts /stylesheets'
  if ADMIN
    use Rack::Session::Cookie, :secret=>SecureRandom.random_bytes(40)
  end

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
    :albums_by_category
  end

  def content_tag(tag, content)
    "<#{tag}>#{content}</#{tag}>"
  end
  
  def date_link(date)
    "#{link_to(date.year, "/albums_by_date/#{date.year}")}-#{'%02i' % date.month }-#{'%02i' % date.day}"
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

  plugin :render, :cache=>!ADMIN, :default_encoding => 'UTF-8', :escape=>true
  plugin :assets,
    :css=>{:public=>%w'bootstrap.min.css falcomcatalog.scss', :admin=>'jquery.autocomplete.css'},
    :js=>{:public=>%w'jquery-1.11.1.min.js bootstrap.min.js', :admin=>%w'jquery.autocomplete.js autoforme.js'},
    :css_opts=>{:style=>:compressed, :cache=>false},
    :compiled_path=>nil,
    :group_subdirs=>false,
    :compiled_css_dir=>'stylesheets',
    :compiled_js_dir=>'javascripts',
    :precompiled=>'compiled_assets.json',
    :prefix=>nil
  plugin :h
  plugin :symbol_matchers
  plugin :symbol_views
  plugin :delegate
  request_delegate :params

  plugin :error_handler do |e|
    $stderr.puts e.message
    e.backtrace.each{|x| $stderr.puts x}
    view(:content=>"<h3>Oops, an error occurred.</h3>")
  end

  plugin :not_found do
    view(:content=>"<h3>The page you are looking for does not exist.</h3>")
  end

  if ADMIN
    plugin :flash
    plugin :autoforme do
      inline_mtm_associations :all
      association_links :all
      form_options :input_defaults=>{:text=>{:size=>80}}

      model Album do
        order :sortname
        columns [:fullname, :sortname, :picture, :numdiscs]
        display_name :fullname
      end
      model Albuminfo do
        columns [:album, :discnumber, :starttrack, :endtrack, :info]
        display_name{|obj| "#{obj.discnumber}-#{obj.starttrack}-#{obj.endtrack}-#{obj.info}"}
      end
      model Artist do
        order :name
      end
      model Discname do
        columns [:album, :number, :name]
      end
      model Game do
        order :name
        columns [:series, :name, :jname]
      end
      model Lyric do
        columns [:rsongname, :jsongname, :joriginalsongname, :arranger, :composer, :lyricist, :vocalist]
        order :song__name
        eager_graph :song
        display_name{|obj| obj.song.name}
      end
      model LyricVerse do
        columns [:lyric, :number, :verse, :languageid]
        order [:lyricsongid, :languageid, :number, :verse]
        display_name{|obj| "Verse #{obj.number} - #{obj.languageid != 3 ? obj.verse[0...40].gsub(/<br? ?\/?>?/, ', ') : 'Japanese text'}"}
      end
      model Mediatype do
        order :name
        columns [:name]
      end
      model Medium do
        columns [:album, :mediatype, :publisher, :catalognumber, :price, :publicationdate]
        display_name :catalognumber
      end
      model Publisher do
        order :name
        columns [:name]
      end
      model Series do
        order :name
        columns [:name]
      end
      model Song do
        order :name
        columns [:name, :game, :lyric, :arrangement]
        autocomplete_options :limit=>15
        display_name{|obj| obj.name[0..50]}
      end
    end

    Forme.register_config(:mine, :base=>:default, :labeler=>:explicit, :wrapper=>:div)
    Forme.default_config = :mine
  end

  route do |r|
    r.assets if ADMIN

    r.root do
      :index
    end

    r.get do 
      r.is %w'feedback index news info order' do |page|
        page.to_sym
      end

      r.is "album/:id" do |id|
        i = id.to_i
        @album = Album[i]
        @discs = []
        @albuminfos = {}
        @album.discnames.length > 0 ? (@album.discnames.each{ |disc| @discs.push({:name=>disc.name, :tracks=>[], :id=>disc.id}) }) : @discs.push({:tracks=>[]})
        @album.tracks.each do |track|
          @discs[track.discnumber-1][:tracks].push track
        end
        @album.albuminfos.each {|info| (@albuminfos[[info.discnumber, info.starttrack]] ||= []) << info}
        @media = Medium.filter(:albumid=>i).order(:media__publicationdate).eager(:mediatype, :publisher).all
        :album
      end

      r.is 'albums_by_date:optd' do |year|
        year = year.to_i if year
        @pagetitle = year ? "Albums Released in #{year}" : 'Albums By Release Date'
        @albums = Medium.find_albums_by_date(year)
        albums_by_category
      end

      r.is 'albums_by_media_type:optd' do |mediatype|
        @albums = Medium.find_albums_by_mediatype(mediatype)
        @pagetitle = if !(mediatype and @albums.length > 0)
          'Albums By Media Type'
        else
          "Albums in #{@albums[0][2]} format"
        end
        albums_by_category
      end

      r.is 'albums_by_name:opt' do |initial|
        @albums = Album.group_all_by_sortname(initial)
        @pagetitle = if !(initial and @albums.length > 0)
          'Albums By Name'
        else
          "Albums Starting with #{initial}"
        end
        albums_by_category
      end
      
      r.is 'albums_by_price:optd' do |price|
        price = price.to_i if price
        @pagetitle = case price
        when nil
          'Albums By Price'
        when 0
          'Albums Not for Sale'
        else
          "Albums Costing #{price} Yen"
        end
        @albums = Medium.find_albums_by_price(price)
        albums_by_category
      end

      r.is "artists" do
        @artists = Artist.order(:name).all
        :artists
      end
      
      r.is "artist/:d" do |id|
        @artist = Artist[id.to_i]
        :artist
      end
      
      r.is "game/:d" do |id|
        @game = Game[id.to_i]
        :game
      end
      
      r.is "games" do
        @games = Game.order(:name)
        :games
      end

      r.is "japanese_lyric/:id" do |id|
        @lyric = Lyric[id.to_i]
        :japanese_lyric
      end

      r.is "lyric/:id" do |id|
        @lyric = Lyric[id.to_i]
        :lyric
      end
      
      r.is "photoboard" do
        @albums = Album.filter(Sequel.negate([[:picture, nil], [:picture, '']])).order{RANDOM{}}
        :photoboard
      end

      r.is "publisher/:d" do |id|
        @publisher = Publisher[id.to_i]
        :publisher
      end
      
      r.is "publishers" do |id|
        @publishers = Publisher.order(:name)
        :publishers
      end
      
      r.is "random_album" do
        r.redirect "/album/#{(rand(Album.count)+1)}"
      end
      
      r.is "random_lyric" do
        r.redirect "/lyric/#{(rand(Lyric.count)+1)}"
      end
      
      r.is "random_song" do
        r.redirect "/song/#{(rand(Song.count)+1)}"
      end
     
      r.is "series/:d" do |id|
        i = id.to_i
        @series = Series.eager_graph(:albums).order(:albums__fullname).filter(:series__id=>i).all.first
        @games = Game.eager_graph(:albums).order(:games__name, :albums__fullname).filter(:games__seriesid=>i).all
        :series
      end
      
      r.is "series_list" do
        @series = Series.order(:name)
        :series_list
      end
      
      r.is "song/:d" do |id|
        @song = Song[id.to_i]
        :song
      end
      
      r.is "song_search_results" do
        @songs = if (songname = r['songname']) && !songname.empty?
          Song.filter(Sequel.ilike(:name, "%#{Song.dataset.escape_like(songname)}%")).order(:name).all
        else
          []
        end
        :song_search_results
      end
      
      if ADMIN
        r.is "new_tracklist/:d" do |id|
          @album = Album[id.to_i]
          r.redirect("/album/#{@album.id}")if @album.tracks.length > 0
          :new_tracklist
        end
      
        r.is "new_tracklist_table/:d" do |id|
          @album = Album[id.to_i]
          @games = Game.order(:name)
          @tracks = @album.tracks_dataset.
            select(:tracks__discnumber, :tracks__number, :tracks__songid, :song__name, :game__name___game, :arrangement__name___arrangement).
            association_left_join(:song=>[:game, :arrangement]).
            order(:tracks__discnumber, :tracks__number)
          :new_tracklist_table
        end

        autoforme
      end
    end
      
    if ADMIN
      r.post do
        r.is "create_tracklist/:d" do |id|
          album = Album[id.to_i]
          album.create_tracklist(params[:tracklist])
          r.redirect "/album/#{album.id}" 
        end

        r.is "update_tracklist_game/:d" do |id|
          Album[id.to_i].update_tracklist_game(params[:disc].to_i, params[:starttrack].to_i, params[:endtrack].to_i, params[:game].to_i)
          r.redirect "/new_tracklist_table/#{id}"
        end

        autoforme
      end
    end
  end
end
