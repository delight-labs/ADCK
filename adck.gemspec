# -*- encoding: utf-8 -*-
require File.expand_path('../lib/adck/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tal Atlas"]
  gem.email         = ["me@tal.by"]
  gem.description   = <<-EOF
    Simple Apple push notification service gem

    Based on the APNS gem by James Pozdena <jpoz@jpoz.net> http://github.com/jpoz/apns
  EOF
  gem.summary       = %q{Simple Apple push notification service gem}
  gem.homepage      = "https://github.com/delight-labs/ADCK"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "adck"
  gem.require_paths = ["lib"]
  gem.version       = ADCK::VERSION

  gem.add_dependency('multi_json')

  gem.add_development_dependency("rspec", ["~> 2.8.0"])
end
