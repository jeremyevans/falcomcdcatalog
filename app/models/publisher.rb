class Publisher < Sequel::Model
  one_to_many :media, :key=>:publisherid, :order=>:publicationdate
  @scaffold_select_order = :name
  @scaffold_fields = [:name]

  def albums
    Album.eager_graph(:media).filter(:media__publisherid => id).order(:sortname).all
  end
end
