#encoding: utf-8

require 'roda'
require 'thamble'
require_relative 'models'

module Falcom
  class App < Roda
    opts[:root] = File.dirname(__FILE__)

    if ADMIN
      use Rack::Session::Cookie, :secret=>SecureRandom.random_bytes(40)
      plugin :strip_path_prefix
      PUBLIC_ROOT = 'public'
    else
      PUBLIC_ROOT = File.join(File.dirname(__FILE__), 'public')
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

    plugin :public, :gzip=>true
    plugin :render, :cache=>!ADMIN, :default_encoding => 'UTF-8', :escape=>:erubi
    plugin :assets,
      :css=>{:public=>%w'bootstrap.min.css falcomcatalog.scss', :admin=>'jquery.autocomplete.css'},
      :js=>{:public=>%w'jquery-1.11.1.min.js bootstrap.min.js', :admin=>%w'jquery.autocomplete.js autoforme.js'},
      :css_opts=>{:style=>:compressed, :cache=>false},
      :compiled_path=>nil,
      :group_subdirs=>false,
      :compiled_css_dir=>'stylesheets',
      :compiled_js_dir=>'javascripts',
      :precompiled=>File.expand_path('../compiled_assets.json', __FILE__),
      :prefix=>nil,
      :gzip=>true
    plugin :h
    plugin :symbol_views
    plugin :typecast_params
    plugin :disallow_file_uploads

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
          class_display_name 'Album'
          order :sortname
          columns [:fullname, :sortname, :picture, :numdiscs]
          display_name :fullname
        end
        model Albuminfo do
          class_display_name 'Albuminfo'
          columns [:album, :discnumber, :starttrack, :endtrack, :info]
          display_name{|obj| "#{obj.discnumber}-#{obj.starttrack}-#{obj.endtrack}-#{obj.info}"}
        end
        model Artist do
          class_display_name 'Artist'
          order :name
        end
        model Discname do
          class_display_name 'Discname'
          columns [:album, :number, :name]
        end
        model Game do
          class_display_name 'Game'
          order :name
          columns [:series, :name, :jname]
        end
        model Lyric do
          class_display_name 'Lyric'
          columns [:rsongname, :jsongname, :joriginalsongname, :arranger, :composer, :lyricist, :vocalist]
          order Sequel[:song][:name]
          eager_graph :song
          display_name{|obj| obj.song.name}
        end
        model LyricVerse do
          class_display_name 'LyricVerse'
          columns [:lyric, :number, :verse, :languageid]
          order [:lyricsongid, :languageid, :number, :verse]
          display_name{|obj| "Verse #{obj.number} - #{obj.languageid != 3 ? obj.verse[0...40].gsub(/<br? ?\/?>?/, ', ') : 'Japanese text'}"}
        end
        model Mediatype do
          class_display_name 'Mediatype'
          order :name
          columns [:name]
        end
        model Medium do
          class_display_name 'Medium'
          columns [:album, :mediatype, :publisher, :catalognumber, :price, :publicationdate]
          display_name :catalognumber
        end
        model Publisher do
          class_display_name 'Publisher'
          order :name
          columns [:name]
        end
        model Series do
          class_display_name 'Series'
          order :name
          columns [:name]
        end
        model Song do
          class_display_name 'Song'
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
      r.public
      r.assets if ADMIN

      r.root do
        :index
      end

      r.get do 
        r.is %w'feedback index news info order' do |page|
          page.to_sym
        end

        r.is "album", Integer do |id|
          @album = Album.with_pk!(id)
          @discs = []
          @albuminfos = {}
          @album.discnames.length > 0 ? (@album.discnames.each{ |disc| @discs.push({:name=>disc.name, :tracks=>[], :id=>disc.id}) }) : @discs.push({:tracks=>[]})
          @album.tracks.each do |track|
            @discs[track.discnumber-1][:tracks].push track
          end
          @album.albuminfos.each {|info| (@albuminfos[[info.discnumber, info.starttrack]] ||= []) << info}
          @media = Medium.filter(:albumid=>id).order(Sequel[:media][:publicationdate]).eager(:mediatype, :publisher).all
          :album
        end

        r.on 'albums_by_date' do
          r.is do
            @pagetitle = 'Albums By Release Date'
            @albums = Medium.find_albums_by_date(nil)
            albums_by_category
          end

          r.is Integer do |year|
            @pagetitle = "Albums Released in #{year}"
            @albums = Medium.find_albums_by_date(year)
            albums_by_category
          end
        end

        r.on 'albums_by_media_type' do
	  r.is do
            @albums = Medium.find_albums_by_mediatype(nil)
            @pagetitle = 'Albums By Media Type'
            albums_by_category
	  end

	  r.is Integer  do |mediatype|
            @albums = Medium.find_albums_by_mediatype(mediatype)
            @pagetitle = "Albums in #{@albums[0][2]} format"
            albums_by_category
	  end
        end

        r.on 'albums_by_name' do
	  r.is do
            @albums = Album.group_all_by_sortname(nil)
            @pagetitle = 'Albums By Name'
            albums_by_category
	  end

	  r.is /(\w)/ do |initial|
            @albums = Album.group_all_by_sortname(initial)
            @pagetitle = "Albums Starting with #{initial}"
            albums_by_category
	  end
        end
        
        r.on 'albums_by_price' do
	  r.is do
            @albums = Medium.find_albums_by_price(nil)
            @pagetitle = 'Albums By Price'
            albums_by_category
	  end

	  r.is Integer do |price|
            @albums = Medium.find_albums_by_price(price)
            @pagetitle = if price == 0
              'Albums Not for Sale'
            else
              "Albums Costing #{price} Yen"
            end
            albums_by_category
	  end
        end

        r.is "artists" do
          @artists = Artist.order(:name).all
          :artists
        end
        
        r.is "artist", Integer do |id|
          @artist = Artist.with_pk!(id)
          :artist
        end
        
        r.is "game", Integer do |id|
          @game = Game.with_pk!(id)
          :game
        end
        
        r.is "games" do
          @games = Game.order(:name)
          :games
        end

        r.is "japanese_lyric", Integer do |id|
          @lyric = Lyric.with_pk!(id)
          :japanese_lyric
        end

        r.is "lyric", Integer do |id|
          @lyric = Lyric.with_pk!(id)
          :lyric
        end
        
        r.is "photoboard" do
          @albums = Album.filter(Sequel.negate([[:picture, nil], [:picture, '']])).order{RANDOM().function}
          :photoboard
        end

        r.is "publisher", Integer do |id|
          @publisher = Publisher.with_pk!(id)
          :publisher
        end
        
        r.is "publishers" do
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
       
        r.is "series", Integer do |id|
          @series = Series.eager_graph(:albums).order(Sequel[:albums][:fullname]).filter(Sequel[:series][:id]=>id).all.first
          @games = Game.eager_graph(:albums).order(Sequel[:games][:name], Sequel[:albums][:fullname]).filter(Sequel[:games][:seriesid]=>id).all
          :series
        end
        
        r.is "series_list" do
          @series = Series.order(:name)
          :series_list
        end
        
        r.is "song", Integer do |id|
          @song = Song.with_pk!(id)
          :song
        end
        
        r.is "song_search_results" do
          @songs = if songname = typecast_params.nonempty_str('songname')
            Song.filter(Sequel.ilike(:name, "%#{Song.dataset.escape_like(songname)}%")).order(:name).all
          else
            []
          end
          :song_search_results
        end
        
        if ADMIN
          r.is "new_tracklist", Integer do |id|
            @album = Album.with_pk!(id)
            r.redirect("/album/#{@album.id}")if @album.tracks.length > 0
            :new_tracklist
          end
        
          r.is "new_tracklist_table", Integer do |id|
            @album = Album.with_pk!(id)
            @games = Game.order(:name)
            @tracks = @album.tracks_dataset.
              select(Sequel[:tracks][:discnumber], Sequel[:tracks][:number], Sequel[:tracks][:songid], Sequel[:song][:name], Sequel[:game][:name].as(:game), Sequel[:arrangement][:name].as(:arrangement)).
              association_left_join(:song=>[:game, :arrangement]).
              order(Sequel[:tracks][:discnumber], Sequel[:tracks][:number])
            :new_tracklist_table
          end

          autoforme
        end
      end
        
      if ADMIN
        r.post do
          r.is "create_tracklist", Integer do |id|
            album = Album.with_pk!(id)
            album.create_tracklist(typecast_params.str!('tracklist'))
            r.redirect "/album/#{album.id}" 
          end

          r.is "update_tracklist_game", Integer do |id|
            Album.with_pk!(id).update_tracklist_game(*typecast_params.pos_int!(%w'disc starttrack endtrack game'))
            r.redirect "/new_tracklist_table/#{id}"
          end

          autoforme
        end
      end
    end
  end
end
