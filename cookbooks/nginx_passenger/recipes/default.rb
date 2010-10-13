#
# Cookbook Name:: nginx_passenger
# Recipe:: default
#
if ['solo', 'util'].include?(node[:instance_role])
  
  worker_count = case node[:ec2][:instance_type]
    when "m1.small"
      3
    when "m1.large"
      6
    when "c1.medium"
      6
    when "c1.xlarge"
      24
    when "m1.xlarge"
      12
    when "m2.2xlarge"
      8
    when "m2.4xlarge"
      24
  end
  
  node[:applications].each do |app, data|
    
    template "/data/nginx/stack.conf" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      source "nginx_stack.conf.erb"
      variables(
        :user => node[:owner_name],
        :worker_count => worker_count
      )
    end

    execute "restart-nginx" do
      command "/etc/init.d/nginx restart"
    end
  end 
end
