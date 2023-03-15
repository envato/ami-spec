lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ami_spec/version'

Gem::Specification.new do |gem|
  gem.name          = 'ami_spec'
  gem.version       = AmiSpec::VERSION
  gem.authors       = ['Patrick Robinson', 'Martin Jagusch']
  gem.email         = []
  gem.description   = 'Acceptance testing your AMIs'
  gem.summary       = gem.description
  gem.homepage      = 'https://github.com/envato/ami-spec'

  gem.files         = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r{^(?:README|LICENSE|CHANGELOG|lib/|bin/)})
  end
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'aws-sdk-ec2', '~> 1'
  gem.add_dependency 'serverspec', '~> 2'
  gem.add_dependency 'specinfra', '>= 2.45'
  gem.add_dependency 'optimist', '~> 3'
  gem.add_dependency 'hashie'
  gem.add_dependency 'net-ssh', '~> 5'

  gem.required_ruby_version = '>= 2.2.6'
end
