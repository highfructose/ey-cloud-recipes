define :passenger_server do
  app = params[:dna_app]

  gem_package "passenger" do
    action :install
    version node[:passenger_version]
  end

  gem_package "fastthread" do
    action :install
  end

  app.vhosts.each do |vhost|

    vhost app.name do
      dna_vhost vhost
      cookbook 'passenger'
      stack_config true
    end
  end

  #TODO: another hack :(
  remote_file '/usr/bin/ruby-for-passenger' do
    cookbook 'nginx'
    owner 'root'
    group 'root'
    mode 0755
    source 'ruby-for-passenger'
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end


  package 'dev-util/lockrun' do
    version '2'
  end

  cron "passenger_monitor_#{app.name}" do
    minute '*'
    hour '*'
    day '*'
    weekday '*'
    month '*'
    command "/usr/bin/lockrun --lockfile=/var/run/passenger_monitor_#{app.name}.lockrun -- /bin/bash -c '/engineyard/bin/passenger_monitor #{app.name} -f #{app.type} >/dev/null 2>&1'"
  end
end
