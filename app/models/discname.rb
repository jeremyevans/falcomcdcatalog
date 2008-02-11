class Discname < ActiveRecord::Base
  belongs_to :album, :foreign_key => 'albumid'
  @scaffold_fields = [:album, :number, :name]
end
