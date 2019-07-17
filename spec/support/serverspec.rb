require 'serverspec'

RSpec.configure do |config|
  config.before :suite do
    set :backend, :exec
  end
end
