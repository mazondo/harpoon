Gem::Specification.new do |s|
  s.name        = 'harpoon'
  s.version     = '0.0.1'
  s.date        = '2013-09-18'
  s.summary     = "A single page app deployer for amazon s3"
  s.description = "Deploy small server-less webapps to amazon s3, including buckets, dns and permissions"
  s.authors     = ["Ryan Quinn"]
  s.email       = 'ryan@mazondo.com'
  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.add_dependency "thor",       "~> 0.18.1"
  s.add_dependency "netrc",       "~> 0.7.7"
  s.add_dependency "aws-sdk",     "~> 1.18.0"
  s.homepage    = 'http://www.github.com/mazondo/harpoon'
end
