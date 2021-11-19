require_relative '.rake_tasks' if File.file?('./.rake_tasks.rb')

desc "Run specs"
task :spec do
  sh %{#{FileUtils::RUBY} unit_test.rb}
  sh %{#{FileUtils::RUBY} test.rb}
end

desc "Find unused associations and association methods"
task :unused_associations do
  ENV['UNUSED_ASSOCIATION_COVERAGE'] = '1'
  sh %{#{FileUtils::RUBY} unused_associations_coverage.rb unit_test.rb}
  sh %{#{FileUtils::RUBY} unused_associations_coverage.rb test.rb}
  require './models'
  Falcom::Model.update_unused_associations_data

  puts "Unused Associations:"
  Falcom::Model.unused_associations.each do |sc, assoc|
    puts "#{sc}##{assoc}"
  end

  puts "Unused Associations Options:"
  Falcom::Model.unused_association_options.each do |sc, assoc, options|
    options.delete(:no_dataset_method)
    next if options.empty?
    puts "#{sc}##{assoc}: #{options.inspect}"
  end
  Falcom::Model.delete_unused_associations_files
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
