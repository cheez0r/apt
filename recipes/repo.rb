#
# Cookbook Name:: apt
# Recipe:: repo
#
# Copyright 2011, Dan Prince.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "nginx::default"

package "reprepro" do
  action :install
end

[
"/var/packages", "/var/packages/apt", "/var/packages/apt/#{node[:apt][:repo_name]}", "/var/packages/apt/#{node[:apt][:repo_name]}/conf", "/var/packages/apt/#{node[:apt][:repo_name]}/dists", "/var/packages/apt/#{node[:apt][:repo_name]}/dists/#{node[:apt][:repo_codename]}", "/var/packages/apt/#{node[:apt][:repo_name]}/dists/#{node[:apt][:repo_codename]}/main"].each do |dirname|
  directory dirname do
    owner "root"
    group "root"
    mode  0755
    action :create
  end
end

template "/var/packages/apt/#{node[:apt][:repo_name]}/conf/distributions" do
  source "distributions.erb"
  mode 0644
  variables(
    :repo_archs => node[:apt][:repo_archs],
    :repo_name => node[:apt][:repo_name],
    :code_name => node[:apt][:repo_codename]
  )
end

file "/var/packages/apt/#{node[:apt][:repo_name]}/conf/override.#{node[:apt][:repo_codename]}" do
  action :touch
end

template "/var/packages/apt/#{node[:apt][:repo_name]}/conf/options" do
  source "options.erb"
  mode 0644
end

if node[:apt][:upload_package_dir] then
  rbfiles = File.join(node[:apt][:upload_package_dir], "*.deb")
  Dir.glob(rbfiles).each do |deb|
    add_deb_to_repo deb do
      repo_dir "/var/packages/apt/#{node[:apt][:repo_name]}"
      codename node[:apt][:repo_codename]
    end
  end
end

# create default Release file (also created by reprepro
release_file="/var/packages/apt/#{node[:apt][:repo_name]}/dists/#{node[:apt][:repo_codename]}/Release"
template release_file do
  source "Release.erb"
  mode 0644
  variables(
    :repo_archs => node[:apt][:repo_archs],
    :repo_name => node[:apt][:repo_name],
    :code_name => node[:apt][:repo_codename]
  )
  not_if { File.exists?(release_file) }
end

# create empty Packages.gz files if needed
node[:apt][:repo_archs].each do |arch|
  directory "/var/packages/apt/#{node[:apt][:repo_name]}/dists/#{node[:apt][:repo_codename]}/main/binary-#{arch}/" do
    owner "root"
    group "root"
    mode  0755
    action :create
  end
  packages_list = "/var/packages/apt/#{node[:apt][:repo_name]}/dists/#{node[:apt][:repo_codename]}/main/binary-#{arch}/Packages.gz"
  execute "echo -n | gzip > #{packages_list}" do
    not_if { File.exists?(packages_list) }
  end
end
