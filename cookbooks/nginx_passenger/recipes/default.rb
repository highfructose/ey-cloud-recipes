#
# Cookbook Name:: nginx_passenger
# Recipe:: default
#
if ['solo', 'util'].include?(node[:instance_role])
  
  node[:applications].each do |app, data|
    
    template "/data/nginx/stack.conf" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      source "nginx_stack.conf.erb"
      variables(
        :user => node[:owner_name],
        :worker_count => get_pool_size()
      )
    end

    execute "restart-nginx" do
      command "/etc/init.d/nginx restart"
    end
  end 
end
