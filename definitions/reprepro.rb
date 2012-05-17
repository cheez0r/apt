define :add_deb_to_repo do

filename=params[:name] # use name param as the repo name
codename=params[:codename]
repo_dir=params[:repo_dir]

bash "reprepro deb: #{filename}" do
  cwd "/tmp"
  user "root"
  code <<-EOH
    cd #{repo_dir}
    reprepro includedeb "#{codename}" "#{filename}"
	rm "#{filename}"
  EOH
  only_if { File.exists?(filename) }
end

end
