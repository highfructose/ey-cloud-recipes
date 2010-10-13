define :nginx_vhost, :stack_config => false, :upstream_ports => [] do
  vhost = params[:dna_vhost]
  app   = vhost.app
  book  = params[:cookbook]
  #TODO: this is the hacky'ist hack ever hacked
  worker_count = params[:worker_count] || get_pool_size()
  upstream_ports = params[:upstream_ports]

  require_recipe 'nginx::setup'

  template "/data/nginx/stack.conf" do
    owner node.engineyard.ssh_username
    group node.engineyard.ssh_username
    mode 0644
    source "nginx_stack.conf.erb"
    cookbook book.to_s

    variables(
      :user         => node.engineyard.ssh_username,
      #TODO: fix this hacky hack
      :worker_count => worker_count
    )

    notifies :run, resources(:execute => "restart-nginx"), :delayed

    only_if { params[:stack_config] }
  end

  file "/data/nginx/stack.conf" do
    action :touch
    owner node.engineyard.ssh_username
    group node.engineyard.ssh_username
    mode 0644
  end

  directory "/data/nginx/servers/#{app.name}" do
    owner node.engineyard.ssh_username
    group node.engineyard.ssh_username
    mode 0775
  end

  managed_template "/data/nginx/servers/#{app.name}.rewrites" do
    owner node.engineyard.ssh_username
    group node.engineyard.ssh_username
    mode 0644
    source "server.rewrites.erb"
    cookbook 'nginx'
    action :create_if_missing

    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  managed_template "/data/nginx/servers/#{app.name}/custom.locations.conf" do
    owner node.engineyard.ssh_username
    group node.engineyard.ssh_username
    mode 0644
    source "custom.locations.conf.erb"
    cookbook 'nginx'
    action :create_if_missing

    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  managed_template "/data/nginx/servers/#{app.name}.conf" do
    owner node.engineyard.ssh_username
    group node.engineyard.ssh_username
    mode 0644
    source "nginx_app.conf.erb"
    cookbook book

    variables :vhost => vhost, :port => node.engineyard.solo? ? 80 : 81,
              :upstream_ports => upstream_ports


    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  if vhost.https?

    managed_template "/data/nginx/servers/#{app.name}.ssl.conf" do
      owner node.engineyard.ssh_username
      group node.engineyard.ssh_username
      mode 0644
      source "nginx_app.conf.erb"
      cookbook book

      variables :vhost => vhost, :ssl => true, :port => node.engineyard.solo? ? 443 : 444

      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end

    template "/data/nginx/ssl/#{app.name}.key" do
      owner node.engineyard.ssh_username
      group node.engineyard.ssh_username
      mode 0644
      source "sslkey.erb"
      variables :key => vhost.ssl_cert.private_key
      backup 0
      cookbook 'nginx'

      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end

    template "/data/nginx/ssl/#{app.name}.crt" do
      owner node.engineyard.ssh_username
      group node.engineyard.ssh_username
      mode 0644
      source "sslcrt.erb"
      variables :chain => vhost.ssl_cert.certificate_chain, :crt => vhost.ssl_cert.certificate
      backup 0
      cookbook 'nginx'

      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end


  else

    # cleanup any old ssl vhosts
    file "/data/nginx/servers/#{app.name}.ssl.conf" do
      action :delete

      only_if "test -f /data/nginx/servers/#{app.name}.ssl.conf"

      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end

  end

end
