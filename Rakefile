require 'yard'
require 'yard/rake/yardoc_task'
 
YARD::Rake::YardocTask.new do |t|
  t.files = %w(
      market.rb
      bitflyer.rb
      btcbox.rb
      coincheck.rb
      zaif.rb
    )
  t.options = []
  t.options = %w(--debug --verbose) if $trace
end

require 'rake/clean'
require 'pp'

CLEAN.include("doc")
