Encoding.default_internal = Encoding.default_external = 'UTF-8'
require File.expand_path('../falcomcdcatalog', __FILE__)
run Falcom::App.freeze.app

require 'tilt/sass' unless File.exist?(File.expand_path('../compiled_assets.json', __FILE__))
Tilt.finalize!
RubyVM::YJIT.enable if defined?(RubyVM::YJIT.enable)

FALCOM_CD_CATALOG_CONFIG_RU_BEFORE_FREEZE.call if defined?(FALCOM_CD_CATALOG_CONFIG_RU_BEFORE_FREEZE)

begin
  require 'refrigerator'
rescue LoadError
else
  Refrigerator.freeze_core
end

FALCOM_CD_CATALOG_CONFIG_RU.call if defined?(FALCOM_CD_CATALOG_CONFIG_RU)
