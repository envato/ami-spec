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

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'aws-sdk-ec2'
  gem.add_dependency 'rake'
  gem.add_dependency 'serverspec'
  gem.add_dependency 'specinfra', '>= 2.45'
  gem.add_dependency 'optimist'
  gem.add_dependency 'hashie'
  gem.add_dependency 'net-ssh', '~> 5'
end
