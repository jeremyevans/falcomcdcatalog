#encoding: utf-8

require_relative 'models'
require 'roda'
require 'thamble'
require 'tilt'
require 'tilt/erubi'

module Falcom
  class App < Roda
    def self.freeze
      Model.freeze_descendents
      DB.freeze
      super
    end

    opts[:root] = File.dirname(__FILE__)
    opts[:check_dynamic_arity] = false
    opts[:check_arity] = :warn

    plugin :direct_call

    if ADMIN
      PUBLIC_ROOT = 'public'
      plugin :route_csrf
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
    plugin :render, :cache=>!ADMIN, :default_encoding => 'UTF-8', :escape=>true, :template_opts=>{:chain_appends=>true, :freeze=>true, :skip_compiled_encoding_detection=>true}
    plugin :assets,
      :css=>{:public=>%w'falcomcatalog.scss', :admin=>'auto-complete.css'},
      :js=>{:public=>%w'app.js', :admin=>%w'auto-complete.min.js autoforme.js'},
      :css_opts=>{:style=>:compressed, :cache=>false},
      :compiled_path=>nil,
      :group_subdirs=>false,
      :compiled_css_dir=>'stylesheets',
      :compiled_js_dir=>'javascripts',
      :css_compressor=>:none,
      :js_compressor=>:none,
      :precompiled=>File.expand_path('../compiled_assets.json', __FILE__),
      :prefix=>nil,
      :gzip=>true
    plugin :h
    plugin :symbol_views
    plugin :Integer_matcher_max
    plugin :typecast_params_sized_integers, :sizes=>[64], :default_size=>64
    alias tp typecast_params
    plugin :disallow_file_uploads
    plugin :request_aref, :raise

    logger = case ENV['RACK_ENV']
    when 'test'
      Class.new{def write(_) end}.new
    else
      $stderr
    end
    plugin :common_logger, logger

    plugin :error_handler do |e|
      case e
      when Roda::RodaPlugins::TypecastParams::Error
        response.status = 400
        view(:content=>"<h1>Invalid parameter submitted: #{h e.param_name}</h1>")
      else
        $stderr.puts "#{e.class}: #{e.message}", e.backtrace
        view(:content=>"<h1>Internal Server Error</h1>")
      end
    end

    plugin :not_found do
      view(:content=>"<h1>The page you are looking for does not exist.</h1>")
    end

    if ADMIN
      plugin :flash

      require 'securerandom'
      plugin :sessions,
        :secret=>SecureRandom.random_bytes(64),
        :key=>'falcomcds.session'

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

    plugin :content_security_policy do |csp|
      csp.default_src :none
      csp.style_src :self, :unsafe_inline
      csp.script_src :self
      csp.connect_src :self
      csp.img_src :self
      csp.form_action :self
      csp.base_uri :none
      csp.frame_ancestors :none
    end

    LIST_TYPES = {
      'artists' => [:@artists, Artist, :artists],
      'games' => [:@games, Game, :games],
      'publishers' => [:@publishers, Publisher, :publishers],
      'series_list' => [:@series, Series, :series_list]
    }.freeze
    LIST_TYPES.each_value(&:freeze)
    LIST_TYPES_ARRAY = LIST_TYPES.keys.freeze

    RANDOM_TYPES = {
      'random_album' => ['album', Album],
      'random_lyric' => ['lyric', Lyric],
      'random_song' => ['song', Song]
    }.freeze
    RANDOM_TYPES.each_value(&:freeze)
    RANDOM_TYPES_ARRAY = RANDOM_TYPES.keys.freeze

    TYPES = {
      "artist" => [:@artist, Artist, :artist],
      "game" => [:@game, Game, :game],
      "japanese_lyric" => [:@lyric, Lyric, :japanese_lyric],
      "lyric" => [:@lyric, Lyric, :lyric],
      "publisher" => [:@publisher, Publisher, :publisher],
      "song" => [:@song, Song, :song]
    }.freeze
    TYPES.each_value(&:freeze)
    TYPES_ARRAY = TYPES.keys.freeze

    route do |r|
      r.get do 
        r.public

        r.root do
          :index
        end

        r.is %w'feedback index news info order' do |page|
          view(page)
        end

        r.is LIST_TYPES_ARRAY do |type|
          iv, klass, template = LIST_TYPES[type]
          instance_variable_set(iv, klass.order(:name).all)
          template
        end

        r.is "photoboard" do
          @albums = Album.filter(Sequel.negate([[:picture, nil], [:picture, '']])).order{RANDOM().function}
          :photoboard
        end

        r.is RANDOM_TYPES_ARRAY do |type|
          segment, klass = RANDOM_TYPES[type]
          r.redirect "/#{segment}/#{(rand(klass.count)+1)}"
        end
        
        r.is "song_search_results" do
          @songs = if songname = tp.nonempty_str('songname')
            Song.filter(Sequel.ilike(:name, "%#{Song.dataset.escape_like(songname)}%")).order(:name).all
          else
            []
          end
          :song_search_results
        end
            
        r.on "album", Integer do |id|
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

        r.on "albums_by_date" do
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

        r.on "albums_by_media_type" do
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

        r.on "albums_by_name" do
          r.is do
            @albums = Album.group_all_by_sortname(nil)
            @pagetitle = 'Albums By Name'
            albums_by_category
          end

          r.is(/(\w)/) do |initial|
            @albums = Album.group_all_by_sortname(initial)
            @pagetitle = "Albums Starting with #{initial}"
            albums_by_category
          end
        end

        r.on "albums_by_price" do
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

        r.is TYPES_ARRAY, Integer do |type, id|
          iv, klass, template = TYPES[type]
          instance_variable_set(iv, klass.with_pk!(id))
          template
        end

        r.is "series", Integer do |id|
          @series = Series.
            eager_graph(:albums).
            order(Sequel[:albums][:fullname]).
            filter(Sequel[:series][:id]=>id).
            all.
            first
          @games = Game.
            eager_graph(:albums).
            order(Sequel[:games][:name], Sequel[:albums][:fullname]).
            filter(Sequel[:games][:seriesid]=>id).
            all
          :series
        end

        if ADMIN
          r.is "new_tracklist", Integer do |id|
            @album = Album.with_pk!(id)
            r.redirect("/album/#{@album.id}")if @album.tracks.length > 0
            :new_tracklist
          end
        
          r.is "new_tracklist_table", Integer do |id|
            @album = Album.with_pk!(id)
            @games = Game.order(:name).all
            @tracks = @album.tracks_dataset.
              select(Sequel[:tracks][:discnumber], Sequel[:tracks][:number], Sequel[:tracks][:songid], Sequel[:song][:name], Sequel[:game][:name].as(:game), Sequel[:arrangement][:name].as(:arrangement)).
              association_left_join(:song=>[:game, :arrangement]).
              order(Sequel[:tracks][:discnumber], Sequel[:tracks][:number]).
              all
            :new_tracklist_table
          end

          r.assets
          autoforme
        end
      end
        
      if ADMIN
        r.post do
          r.is "create_tracklist", Integer do |id|
            album = Album.with_pk!(id)
            album.create_tracklist(tp.str!('tracklist'))
            r.redirect "/album/#{album.id}" 
          end

          r.is "update_tracklist_game", Integer do |id|
            Album.with_pk!(id).update_tracklist_game(*tp.pos_int!(%w'disc starttrack endtrack game'))
            r.redirect "/new_tracklist_table/#{id}"
          end

          autoforme
        end
      end
    end
  end
end
