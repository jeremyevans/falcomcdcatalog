class FalcomController < ApplicationController
  before_filter :require_admin_for_scaffolding
  helper_method :admin?
  hide_action :admin?
  
  scaffold_all_models
  scaffolded_methods.delete('index')
  
  def admin?
    ADMIN
  end
    
  def album
    i = params[:id].to_i
    @album = Album[i]
    @discs = []
    @albuminfos = {}
    @album.discnames.length > 0 ? (@album.discnames.each{ |disc| @discs.push({:name=>disc.name, :tracks=>[], :id=>disc.id}) }) : @discs.push({:tracks=>[]})
    Track.filter(:albumid=>i).eager(:song).order(:tracks__discnumber, :tracks__number).each do |track|
      @discs[track.discnumber-1][:tracks].push track
    end
    @album.albuminfos.each {|info| (@albuminfos[[info.discnumber, info.starttrack]] ||= []) << info}
    @media = Medium.filter(:albumid=>i).order(:media__publicationdate).eager(:mediatype, :publisher)
  end

  def albums_by_date
    year = params[:id].to_i if params[:id]
    @pagetitle = year ? "Albums Released in #{year}" : 'Albums By Release Date'
    @albums = Medium.find_albums_by_date(year)
    albums_by_category
  end

  def albums_by_media_type
    mediatype = params[:id].to_i if params[:id]
    @albums = Medium.find_albums_by_mediatype(mediatype)
    @pagetitle = if !(mediatype and @albums.length > 0)
        'Albums By Media Type'
    else "Albums in #{@albums[0][2]} format"
    end
    albums_by_category
  end

  def albums_by_name
    initial = params[:id][0...1] if params[:id]
    @albums = Album.group_all_by_sortname(initial)
    @pagetitle = if !(initial and @albums.length > 0)
        'Albums By Name'
    else "Albums Starting with #{initial}"
    end
    albums_by_category
  end
  
  def albums_by_price
    price = params[:id].to_i if params[:id]
    @pagetitle = case price
      when nil then 'Albums By Price'
      when 0 then 'Albums Not for Sale'
      else "Albums Costing #{price} Yen"
    end
    @albums = Medium.find_albums_by_price(price)
    albums_by_category
  end

  def artist
    @artist = Artist[params[:id].to_i]
  end
  
  def create_tracklist
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
    redirect_to "/album/#{album.id}" 
  end

  def game
    @game = Game[params[:id].to_i]
  end
  
  def games
    @games = Game.order(:name)
  end

  def japanese_lyric
    lyric
    @charset = 'utf-8'
  end

  def lyric
    @lyric = Lyric[params[:id].to_i]
  end
  
  def new_tracklist
    @album = Album[params[:id].to_i]
    redirect_to "/album/#{@album.id}" if @album.tracks.length > 0
  end
  
  def new_tracklist_table
    @album = Album[params[:id].to_i]
    @games = Game.order(:name)
    @tracks = Track.select(:tracks__id, :tracks__discnumber, :tracks__number, :tracks__songid, :songs__name, :games__name___game, :arrangements__name___arrangement).left_outer_join(:songs, :id=>:songid).left_outer_join(:games, :id=>:gameid).left_outer_join(:songs, {:id=>:songs__arrangementof}, :arragements).filter(:tracks__albumid => @album.id).order(:tracks__discnumber, :tracks__number)
  end
  
  def photoboard
    @albums = Album.filter([[:picture, nil], [:picture, '']].sql_negate).order(:RANDOM[])
  end

  def publisher
    @publisher = Publisher[params[:id].to_i]
  end
  
  def publishers
    @publishers = Publisher.order(:name)
  end
  
  def random_album
    redirect_to :action=>"album", :id=>(rand(Album.count)+1).to_s
  end
  
  def random_lyric
    redirect_to :action=>"lyric", :id=>(rand(Lyric.count)+1).to_s
  end
  
  def random_song
    redirect_to :action=>"song", :id=>(rand(Song.count)+1).to_s
  end
 
  def series
    i = params[:id].to_i
    @series = Series.eager_graph(:albums).order(:albums__fullname).filter(:series__id=>i).all.first
    @games = Game.eager_graph(:albums).order(:games__name, :albums__fullname).filter(:games__seriesid=>i).all
  end
  
  def series_list
    @series = Series.order(:name)
  end
  
  def song
    i = params[:id].to_i
    @song = Song[i]
    @tracks = Track.eager_graph(:album).order(:album__fullname, :tracks__discnumber, :tracks__number).filter(:tracks__songid=>i).all
  end
  
  def song_search_results
    @songs = Song.filter(:name.ilike("%#{params[:songname]}%")).order(:name).all
  end
  
  def update_tracklist_game
    tracks = Track.filter(:albumid=>params[:id].to_i, :discnumber=>params[:disc].to_i, :number=>((params[:starttrack].to_i)..(params[:endtrack].to_i)))
    Song.filter(:id=>tracks.map(:songid)).update(:gameid=>params[:game].to_i)
    redirect_to "/new_tracklist_table/#{params[:id]}"
  end
  
  private

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
    render :action=>'albums_by_category'
  end

  def require_admin_for_scaffolding
    render(:text=>'Access Denied', :status=>'403') if scaffolded_method?(params[:action]) && !admin?
  end
end
