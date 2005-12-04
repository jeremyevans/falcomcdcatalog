class Medium < ActiveRecord::Base
    belongs_to :album, :foreign_key => 'albumid'
    belongs_to :mediatype, :foreign_key => 'mediatypeid'
    belongs_to :publisher, :foreign_key => 'publisherid'
    @scaffold_fields = %w'album mediatype publisher catalognumber price publicationdate'
    
    def self.find_albums_by_date(year = nil)
        conditions = ['EXTRACT(YEAR FROM publicationdate) = ?', year] if year
        find(:all, :include=>:album, :conditions=>conditions, :order=>'publicationdate, albums.sortname').collect{|item| [item.publicationdate, item.album, item.publicationdate.year]}.uniq
    end
    
    def self.find_albums_by_mediatype(mediatype = nil)
        conditions = ['mediatypeid = ?', mediatype] if mediatype
        find(:all, :include=>[:album, :mediatype], :conditions=>conditions, :order=>'mediatypes.name, albums.sortname').collect{|item| [item.mediatype.name, item.album, item.mediatype.name]}.uniq
    end

    def self.find_albums_by_price(price = nil)
        conditions = if not price
            nil
        elsif price == 0
            'price IS NULL'
        else
            ['price = ?', price]
        end
        find(:all, :include=>:album, :conditions=>conditions, :order=>'price, albums.sortname').collect{|item| [item.price, item.album, item.price]}.uniq
    end

    def price
        self[:price] ? "#{self[:price]} Yen" : 'Not for Sale'
    end
    
    def priceid
        self[:price] || 0
    end
end
