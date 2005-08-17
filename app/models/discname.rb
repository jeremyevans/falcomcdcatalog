class Discname < ActiveRecord::Base
  belongs_to :album, :foreign_key => 'albumid'
  @scaffold_fields = %w'album number name'
end
