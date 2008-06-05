class Discname < Sequel::Model
  many_to_one :album, :key => :albumid
  @scaffold_fields = [:album, :number, :name]
end
