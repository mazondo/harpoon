Gem::Specification.new do |s|
  s.name        = 'harpoon'
  s.version     = '0.0.2'
  s.date        = '2014-08-20'
  s.summary     = "A single page app deployer for amazon s3"
  s.description = "Deploy small server-less webapps to amazon s3, including buckets, dns and permissions"
  s.authors     = ["Ryan Quinn"]
  s.email       = 'ryan@mazondo.com'
  s.licenses     = ["MIT"]
  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.add_dependency "thor",       "~> 0.19.1"
  s.add_dependency "netrc",       "~> 0.7.7"
  s.add_dependency "aws-sdk",     "~> 1.51.0"
  s.add_dependency "public_suffix", "~> 1.4.5"
  s.add_dependency 'colorize', '~> 0.7.3'
  s.homepage    = 'http://www.getharpoon.com'
end
