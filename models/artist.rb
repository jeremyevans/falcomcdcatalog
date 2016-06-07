class Artist < Sequel::Model
  one_to_many :songs, :order=>:songs__name, :dataset=>proc{|r| r.associated_dataset.select_all(:songs).join(Lyric, {:id=>:lyricid, id=>[:composer_id, :arranger_id, :vocalist_id, :lyricist_id]}, :qualify=>:symbol)}, :eager_loader=>(proc do |eo|
      h = eo[:id_map]
      ids = h.keys
      records = eo[:rows]
      records.each{|r| r.associations[:songs] = []}
      Song.select_all(:songs).select_more(:lyricsongs__composer_id, :lyricsongs__arranger_id, :lyricsongs__vocalist_id, :lyricsongs__lyricist_id).join(Lyric, {:id=>:lyricid}, :table_alias=>:lyricsongs){Sequel.or(:composer_id=>ids, :arranger_id=>ids, :vocalist_id=>ids, :lyricist_id=>ids)}.order(:songs__name).all do |song|
        [:composer_id, :arranger_id, :vocalist_id, :lyricist_id].each do |x|
          recs = h[song.values.delete(x)]
          recs.each{|r| r.associations[:songs] << song} if recs
        end
      end
      records.each{|r| r.associations[:songs].uniq!}
    end)
end

# Table: artists
# Columns:
#  id    | integer | PRIMARY KEY DEFAULT nextval('artists_id_seq'::regclass)
#  name  | text    |
#  jname | text    |
# Indexes:
#  artists_pkey | PRIMARY KEY btree (id)
