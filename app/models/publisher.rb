class Publisher < ActiveRecord::Base
    has_many :media, :foreign_key=>'publisherid', :order=>'publicationdate'
    @scaffold_select_order = 'name'
    @scaffold_fields = %w'name'

    def albums
        Album.find(:all, :include=>:media, :conditions=>['publisherid = ?', id], :order=>'sortname')
    end
end
