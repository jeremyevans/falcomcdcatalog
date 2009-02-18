puts "Starting"
Rack::Handler.get('mongrel').run(FALCOMCDCATALOG, :Host=>'0.0.0.0', :Port=>3001) do |server|
  trap(:INT) do
    server.stop
    puts "Stopping"
  end
end
