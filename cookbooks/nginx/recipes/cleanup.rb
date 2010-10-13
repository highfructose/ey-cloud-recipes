#TODO: uber hacks are uber
(node[:removed_applications]||[]).each do |app|

  directory "/data/nginx/servers/#{app}" do
    action :delete
    recursive true

    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  file "/data/nginx/servers/#{app}.conf" do
    action :delete

    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end
end
