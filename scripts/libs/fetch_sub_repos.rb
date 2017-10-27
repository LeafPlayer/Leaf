#!/usr/bin/env ruby
def update_sub_repos(dependencies_folder)
  base_folder = "#{dependencies_folder}/sub_modules"
  Dir.entries(base_folder).each do |folder|
    if File.directory?(folder) == false
      puts "git fetch --prune --tags #{folder}"
      path = File.join(base_folder, folder)
      Dir.chdir(path)
      system("git pull && git fetch --prune --tags")
      Dir.chdir(base_folder)
    end
  end
end

def fetch_sub_repos(cartfile, dependencies_folder)
  folder = "#{dependencies_folder}/sub_modules"
  FileUtils.mkdir_p(folder,{})

  total_repo_cmds = Array.new
  File.open(cartfile, "r") do |infile|
    while (line = infile.gets)
        if line != "" && line != "#"
          values = line.split
          if values.count >= 2
            repo_address = ""
            cmd = "git clone "
            repo = values[1].gsub(/'/,'')
            repo = repo.gsub(/"/,'')
            if values[0] == "git"
              repo_address = repo
            else
              repo_address = "git@github.com:#{repo}.git"
            end
            if values.count == 3
              branch = values[2].gsub(/'/,'')
              branch = branch.gsub(/"/,'')
              cmd += "-b #{branch} #{repo_address}"
            else
              cmd += "#{repo_address}"
            end
            if cmd != ""
              total_repo_cmds.push(cmd)
            end
          end
        end
    end
  end

  Dir.chdir(folder)
  total_repo_cmds.each do |cmd|
    system(cmd)
  end
end
