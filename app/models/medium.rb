class Medium < Sequel::Model
    many_to_one :album, :key => :albumid
    many_to_one :mediatype, :key => :mediatypeid
    many_to_one :publisher, :key => :publisherid
    @scaffold_fields = [:album, :mediatype, :publisher, :catalognumber, :price, :publicationdate]
    
    def self.find_albums_by_date(year = nil)
        ds = year ? filter(:EXTRACT['YEAR FROM publicationdate'.lit] => year) : self
        ds.eager_graph(:album).order(:publicationdate.desc, :album__sortname).all.collect{|item| [item.publicationdate, item.album, item.publicationdate.year]}.uniq
    end
    
    def self.find_albums_by_mediatype(mediatype = nil)
        ds = mediatype ? filter(:mediatypeid => mediatype) : self
        ds.eager_graph(:album, :mediatype).order(:mediatype__name, :album__sortname).all.collect{|item| [item.mediatype.name, item.album, item.mediatype.name]}.uniq
    end

    def self.find_albums_by_price(price = nil)
        ds = case price
        when nil then self
        when 0 then filter(:price=>nil)
        else filter(:price=>price)
        end
        ds.eager_graph(:album).order(:price, :album__sortname).all.collect{|item| [item.price, item.album, item.price]}.uniq
    end

    def price
        self[:price] ? "#{self[:price]} Yen" : 'Not for Sale'
    end
    
    def priceid
        self[:price] || 0
    end
      
    def scaffold_name
      catalognumber
    end
end
