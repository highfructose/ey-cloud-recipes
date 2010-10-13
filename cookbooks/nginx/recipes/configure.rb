## /data/nginx/
remote_file "/data/nginx/mime.types" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  source "mime.types"
end

remote_file "/data/nginx/koi-utf" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  source "koi-utf"
end

remote_file "/data/nginx/koi-win" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  source "koi-win"
end

managed_template "/data/nginx/nginx.conf" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0644
  source "nginx-plusplus.conf.erb"
  variables :user => node.engineyard.ssh_username

  notifies :run, resources(:execute => "restart-nginx"), :delayed
end


## /data/nginx/servers/

directory "/data/nginx/servers" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0755
  recursive true
end

file "/data/nginx/servers/default.conf" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0644

  notifies :run, resources(:execute => "restart-nginx"), :delayed
end

## /data/nginx/ssl/

directory "/data/nginx/ssl" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0775
end

## /data/nginx/common/

directory "/data/nginx/common" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0755
  recursive true
end

managed_template "/data/nginx/common/proxy.conf" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0644
  source "common.proxy.conf.erb"

  notifies :run, resources(:execute => "restart-nginx"), :delayed
end

managed_template "/data/nginx/common/servers.conf" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0644
  source "common.servers.conf.erb"

  notifies :run, resources(:execute => "restart-nginx"), :delayed
end

managed_template "/data/nginx/common/fcgi.conf" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0644
  source "common.fcgi.conf.erb"

  notifies :run, resources(:execute => "restart-nginx"), :delayed
end

## /var

directory "/var/log/engineyard/nginx" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username
  mode 0775
end

logrotate "nginx" do
  files "/var/log/engineyard/nginx/*.log /var/log/engineyard/nginx/error_log"
  restart_command <<-SH
[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
  SH
end

#TODO: not_if-afy. https://github.com/engineyard/cloud_cookbooks/commit/73e08722ec930cb8884e44594f6350e25c05c509
unless File.symlink?("/var/log/nginx")
  directory "/var/log/nginx" do
    action :delete
    recursive true
  end
end

#TODO: do this on the AMI/ebuild?
link "/var/log/nginx" do
  to "/var/log/engineyard/nginx"
end

#TODO: do this on the AMI/ebuild?
directory "/var/tmp/nginx/client" do
  owner node.engineyard.ssh_username
  group node.engineyard.ssh_username

  mode 0775
  recursive true
end

## setup /etc/conf.d

managed_template "/etc/conf.d/nginx" do
  source "conf.d/nginx.erb"
  variables({
      :nofile => 16384
  })
  notifies :run, resources(:execute => "restart-nginx"), :delayed
end
