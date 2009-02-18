puts "Starting"
Rack::Handler.get('scgi').run(FALCOMCDCATALOG, :Host=>'127.0.0.1', :Port=>4000) do |server|
  trap(:INT) do
    server.stop
    puts "Stopping"
  end
end
