class FalcomController < ApplicationController
  before_filter { |c| false if c.params[:action] =~ /^(new|edit|update|create|destroy|manage|merge|search)_/ and c.request.env['REMOTE_ADDR'] !~ /^192.168.1/ }
  scaffold(:album, :suffix=>true, :habtm=>[:game, :series])
  scaffold(:albuminfo, :suffix=>true)
  scaffold(:discname, :suffix=>true)
  scaffold(:game, :suffix=>true, :habtm=>:album)
  scaffold(:medium, :suffix=>true)
  scaffold(:publisher, :suffix=>true)
  scaffold(:series, :suffix=>true, :habtm=>:album)
  scaffold(:song, :suffix=>true)
  scaffold(:track, :suffix=>true)
    
  def album
    @album = Album.find(params[:id])
    @discs = []
    @albuminfos = {}
    @album.discnames.length > 0 ? (@album.discnames.each{ |disc| @discs.push({:name=>disc.name, :tracks=>[], :id=>disc.id}) }) : @discs.push({:tracks=>[]})
    Track.find(:all, :conditions => ['albumid = ?', params[:id]], :order=>'tracks.discnumber, tracks.number', :include=>[:song]).each do |track|
      @discs[track.discnumber-1][:tracks].push track
    end
    @album.albuminfos.each {|info| (@albuminfos[[info.discnumber, info.starttrack]] ||= []) << info}
    @media = Medium.find(:all, :conditions => ['albumid = ?', params[:id]], :order=>'media.publicationdate', :include=>[:mediatype, :publisher])
  end

  def albums_by_date
    year = params[:id].to_i if params[:id]
    @include_category = true
    @pagetitle = year ? "Albums Released in #{year}" : 'Albums By Release Date'
    @albums = Medium.find_albums_by_date(year)
    albums_by_category
  end

  def albums_by_media_type
    mediatype = params[:id].to_i if params[:id]
    @albums = Medium.find_albums_by_mediatype(mediatype)
    @pagetitle = if !(mediatype and @albums.length > 0)
        'Albums By Media Type'
    else "Albums in #{@albums[0][0]} format"
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
    albums_by_category(false)
  end

  def artist
    @artist = Artist.find(params[:id])
  end
  
  def create_tracklist
    album = Album.find(params[:id])
    if album.tracks.length == 0  
      songs = {}
      Song.find(:all).each {|s| songs[s.name.downcase.gsub(/\s/, "")] = s.id}
      disctracklists = params[:tracklist].strip.gsub("\r", "").split(/\n\n+/)
      Album.transaction do
        disctracklists.each_with_index do |tracklist, i| i+=1
          Discname.create({:albumid=>album.id, :number=>i, :name=>"Disc #{i}"}) if disctracklists.length > 1
          tracklist.split("\n").each_with_index do |track, j| j+=1
            track = track.strip.gsub('&', "&amp;").gsub('"', "&quot;")
            songid = track == '-' ? 1 : (songs[track.downcase.gsub(/\s/, "")] || (songs[track.downcase.gsub(/\s/, "")] = Song.create({:name=>track}).id)) 
            Track.create({:albumid=>album.id, :discnumber=>i, :number=>j, :songid=>songid})
          end
        end
      end
    end
    redirect_to "/falcom/album/#{album.id}" 
  end

  def game
    @game = Game.find(params[:id])
  end
  
  def games
    @games = Game.find(:all, :order=>'name')
  end

  def japanese_lyric
    lyric
    @charset = 'utf-8'
  end

  def lyric
    @lyric = Lyric.find(params[:id])
  end
  
  def new_tracklist
    @album = Album.find(params[:id])
    redirect_to "/falcom/album/#{@album.id}" if @album.tracks.length > 0
  end
  
  def new_tracklist_table
    @album = Album.find(params[:id])
    @games = Game.find(:all, :order=>'name')
    @tracks = Track.find_by_sql(['SELECT tracks.id, tracks.discnumber, tracks.number, tracks.songid, songs.name, games.name AS game, arrangements.name AS arrangement FROM tracks LEFT JOIN songs ON songid = songs.id LEFT JOIN games ON gameid = games.id LEFT JOIN songs AS arrangements ON songs.arrangementof = arrangements.id WHERE tracks.albumid = ? ORDER BY tracks.discnumber, tracks.number', @album.id])
  end
  
  def photoboard
    @albums = Album.find(:all, :conditions=>"picture IS NOT NULL AND picture != ''", :order=>(static? ? 'fullname' : 'RANDOM()'))
  end

  def publisher
    @publisher = Publisher.find(params[:id])
  end
  
  def publishers
    @publishers = Publisher.find(:all, :order=>'name')
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
    @series = Series.find(params[:id], :include=>:albums, :order=>'fullname')
    @games = Game.find(:all, :conditions=>['seriesid = ?', params[:id]], :include=>:albums, :order=>'games.name, fullname')
  end
  
  def series_list
    @series = Series.find(:all, :order=>'name')
  end
  
  def song
    @song = Song.find(params[:id], :include=>:game)
    @tracks = Track.find(:all, :conditions=>['songid = ?', params[:id]], :include => [:album], :order=>'fullname, tracks.discnumber, tracks.number')
  end
  
  def song_search_results
    @songs = Song.find(:all, :conditions=>['name ILIKE ?', '%%%s%%' % params[:songname]], :order=>'name')
  end
  
  def update_tracklist_game
    songs = Track.find(:all, :conditions=>['albumid = ? AND discnumber = ? AND number BETWEEN ? and ?', params[:id], params[:disc], params[:starttrack], params[:endtrack]]).collect{|t| t.songid.to_s}.compact
    Song.connection.update('UPDATE songs SET gameid = %i WHERE id IN (%s)' % [params[:game].to_i, songs.join(',')])
    redirect_to "/falcom/new_tracklist_table/#{params[:id]}"
  end
  
  private
  def albums_by_category(sort_by_category = true)
    @groups = {}
    @albums.each {|category, album, separator| (@groups[separator] ||= []) << [category, album] }
    @groups = sort_by_category ? @groups.sort : @groups.sort {|a,b| a[1][0][0].to_i <=> b[1][0][0].to_i}
    render 'falcom/albums_by_category'
  end

  def static?
    request.env.include?('HTTP_STATIC')
  end
  helper_method :static?
  
end
