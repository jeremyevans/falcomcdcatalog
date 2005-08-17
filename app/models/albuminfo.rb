class Albuminfo < ActiveRecord::Base
  belongs_to :album, :foreign_key => 'albumid'
  @scaffold_fields = %w'album discnumber starttrack endtrack info'
end
