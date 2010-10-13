if node.engineyard.environment.stack.passenger?
  node.engineyard.apps.each do |app|
    template "/engineyard/bin/app_#{app.name}" do
      source "app_control.erb"
      mode 0755
      owner node[:owner_name]
      group node[:owner_name]
      backup 0
      variables({
        :app_name => app.name
      })
    end
  end
end
