# frozen_string_literal: true
require 'coverage'

Coverage.start(methods: true)

require_relative(ARGV[0])

Minitest.after_run do
  Falcom::Model.update_associations_coverage
end
