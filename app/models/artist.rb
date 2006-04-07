class Artist < ActiveRecord::Base
    def songs
        Song.find(:all, :joins=>'JOIN lyricsongs l ON l.id=lyricid', :conditions=>['l.composer_id = ? OR l.arranger_id = ? OR l.vocalist_id = ? OR l.lyricist_id = ?', id, id, id, id], :order=>'songs.name')
    end
end
