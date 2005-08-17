class Artist < ActiveRecord::Base
    def songs
        Song.find(:all, :joins=>'JOIN lyricsongs l ON l.id=lyricid', :conditions=>['l.composer = ? OR l.arranger = ? OR l.vocalist = ? OR l.lyricist = ?', id, id, id, id], :order=>'songs.name')
    end
end
