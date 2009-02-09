ADMIN=true
DB = Sequel.postgres('falcomcdcatalog', :user=>'_postgresql', :logger=>Logger.new($stdout))
