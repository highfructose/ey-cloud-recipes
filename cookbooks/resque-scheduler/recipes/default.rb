#
# Cookbook Name:: resque-scheduler
# Recipe:: default
#
if ['solo', 'util'].include?(node[:instance_role])
  
  execute "install resque-scheduler gem" do
    command "gem install resque-scheduler -r"
    not_if { "gem list | grep resque-scheduler" }
  end

  node[:applications].each do |app, data|
    
    directory "/var/run/engineyard/resque_scheduler/#{app}" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
      recursive true
    end
    
    template "/engineyard/bin/resque_scheduler" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
      source "resque_scheduler.erb"
    end
    
    template "/etc/monit.d/resque_scheduler_#{app}.monitrc" do 
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644 
      source "monitrc.conf.erb" 
      variables({
        :app_name => app, 
        :rails_env => node[:environment][:framework_env] 
      }) 
    end

    execute "ensure-resque-scheduler-is-setup-with-monit" do 
      command %Q{ 
        monit reload 
      } 
    end

    execute "restart-resque-scheduler" do 
      command %Q{ 
        echo "sleep 20 && monit -g #{app}_resque_scheduler restart all" | at now 
      }
    end
  end 
end
