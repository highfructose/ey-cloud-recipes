## This needs to be declared before it can be executed in a delayed notification.
execute "restart-nginx" do
  command "/etc/init.d/nginx restart"
  action :nothing
end

require_recipe 'nginx::configure'
require_recipe 'nginx::cleanup'

## link config

link "/etc/nginx" do
  to "/data/nginx"
end

## install

package "www-servers/nginx" do
  version '0.6.35-r27'
end

remote_file "/etc/init.d/nginx" do
  owner "root"
  group "root"
  mode 0755
  source "nginx"
end

# This should become a service resource, once we have it for gentoo
runlevel 'nginx' do
  action :add
end


