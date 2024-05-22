Encoding.default_internal = Encoding.default_external = 'UTF-8'
require File.expand_path('../falcomcdcatalog', __FILE__)
run Falcom::App.freeze.app

require 'tilt/sass' unless File.exist?(File.expand_path('../compiled_assets.json', __FILE__))
Tilt.finalize!
RubyVM::YJIT.enable if defined?(RubyVM::YJIT.enable)

begin
  require 'refrigerator'
rescue LoadError
else
  Refrigerator.freeze_core
end
