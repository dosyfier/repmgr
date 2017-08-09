#
# Cookbook Name:: repmgr
# Recipe:: repmgr_daemon
#
# This recipe installs `repmgrd` as a daemon without activating/starting it (which is 
# done by the `setup` recipe depending on whether the current node should be configured
# as a standby or a master one).
#
# Copyright (c) 2017 The Authors, All Rights Reserved.


case node[:repmgr][:init][:type].to_s
when 'runit'
  include_recipe 'runit'
  runit_service 'repmgrd' do
    default_logger true
    run_template_name 'repmgrd'
  end

when 'upstart'
  raise "Not currently supported init type (upstart)"

when 'systemd'
  systemd_unit 'repmgrd.service' do
    content <<-EOU.gsub(/^\s+/, '')
    [Unit]
    Description=Repmgr daemon which actively monitors servers in a PostgreSQL replciation cluster.
    After=network-online.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/repmgrd -f #{node[:repmgr][:config_file_path]} #{ '--monitoring-history' if node[:repmgr][:init][:enable_monitoring] }
    User=postgres
    Group=postgres

    [Install]
    WantedBy=multi-user.target
    EOU

    action :create
  end

else
  template '/etc/init.d/repmgrd' do
    source 'repmgrd.initd.erb'
    mode '0755'
    variables(
      :el => node.platform_family == 'rhel'
    )
    if(File.exists?('/etc/init.d/repmgrd'))
      notifies :restart, 'service[repmgrd]'
    end
  end
end

