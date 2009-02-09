class Publisher < Sequel::Model
  one_to_many :media, :key=>:publisherid, :order=>:publicationdate
  one_to_many :albums, :read_only=>true, :dataset=>proc{Album.eager_graph(:media).filter(:media__publisherid=>id).order(:sortname)}, :eager_loader=>(proc do |key_hash, records, associations|
      h = key_hash[:id]
      records.each{|r| r.associations[:albums] = []}
      Album.eager_graph(:media).filter(:media__publisherid=>h.keys).order(:sortname).all do |a|
        a.media.each do |m|
          if recs = h[m.publisherid]
            recs.each do |r| 
              r.associations[:albums] << a
              m.associations[:publisher] = r
            end
          end
        end
      end
      records.each{|r| r.associations[:albums].uniq!}
    end)
  @scaffold_select_order = :name
  @scaffold_fields = [:name]
end