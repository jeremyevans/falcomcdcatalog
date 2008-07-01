class Artist < Sequel::Model
  one_to_many :songs, :order=>:songs__name, :dataset=>proc{Song.select(:songs.*).join(Lyric, :id=>:lyricid, id=>[:composer_id, :arranger_id, :vocalist_id, :lyricist_id])}, :eager_loader=>(proc do |key_hash, records, associations|
      h = key_hash[:id]
      ids = h.keys
      records.each{|r| r.associations[:songs] = []}
      Song.select(:songs.*, :lyricsongs__composer_id, :lyricsongs__arranger_id, :lyricsongs__vocalist_id, :lyricsongs__lyricist_id).join(Lyric, :id=>:lyricid){{:composer_id=>ids, :arranger_id=>ids, :vocalist_id=>ids, :lyricist_id=>ids}.sql_or}.order(:songs__name).all do |song|
        [:composer_id, :arranger_id, :vocalist_id, :lyricist_id].each do |x|
          recs = h[song.values.delete(x)]
          recs.each{|r| r.associations[:songs] << song} if recs
        end
      end
      records.each{|r| r.associations[:songs].uniq!}
    end)
end
