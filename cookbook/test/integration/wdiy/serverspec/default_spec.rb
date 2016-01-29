require 'serverspec'

# Required by serverspec
set :backend, :exec
set :path, '/opt/rbenv/bin:/opt/rbenv/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

describe command('ruby --version') do
  its(:stdout) { should include '2.1.1' }
end