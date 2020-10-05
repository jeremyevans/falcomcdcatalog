require_relative '.rake_tasks' if File.file?('./.rake_tasks.rb')

desc "Run specs"
task :spec do
  sh %{#{FileUtils::RUBY} unit_test.rb}
  sh %{#{FileUtils::RUBY} test.rb}
end

desc "Run specs"
task :default=>[:spec]

namespace :assets do
  desc "Precompile the assets"
  task :precompile do
    require './falcomcdcatalog'
    Falcom::App.compile_assets
  end
end

desc "Annotate Sequel models"
task "annotate" do
  ENV['RACK_ENV'] = 'development'
  require_relative 'models'
  require 'sequel/annotate'
  Sequel::Annotate.annotate(Dir['models/*.rb'], :namespace=>true)
end
