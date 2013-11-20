class Discname < Sequel::Model
  many_to_one :album, :key => :albumid
end
