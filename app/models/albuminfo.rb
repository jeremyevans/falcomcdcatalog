class Albuminfo < Sequel::Model
  many_to_one :album, :key => :albumid
  @scaffold_fields = [:album, :discnumber, :starttrack, :endtrack, :info]
  
  def scaffold_name
    "#{discnumber}-#{starttrack}-#{endtrack}-#{info}"
  end
end
