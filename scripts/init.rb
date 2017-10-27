#!/usr/bin/env ruby
require "colorize"
require "colorized_string"

require_relative "libs/project_manager.rb"
require_relative "libs/extensions.rb"
require_relative "libs/change_lib_dependencies.rb"
require_relative "libs/utils.rb"
require_relative "libs/integrate_doc_types.rb"
require_relative "libs/parse_doc.rb"
require_relative "libs/fetch_sub_repos.rb"
require_relative "libs/install_tools.rb"

current_folder = `pwd`.gsub(/\n/,'')
project_dir = ""
if current_folder.end_with? "scripts"
  project_dir = File.expand_path("..", current_folder)
else
  project_dir = current_folder
end

project_dir = project_dir

xcodeproj_file = "#{project_dir}/Leaf.xcodeproj"

Dependencies_folder = "#{project_dir}/dependencies"
puts Dependencies_folder
Info_plist_path = "#{project_dir}/Leaf/Support/Info.plist"
assets_path = "#{project_dir}/Leaf/Assets.xcassets"
cartfile_path = "#{Dependencies_folder}/Cartfile"
MANAGER = ProjectManager.new(:project => "#{xcodeproj_file}", :target => "#{Xcodeproj::Project.TargetName}")

def integrate_project_with_dylibs_and_script
  copy_and_change_dylib_dependencies(Dependencies_folder)
  copy_include_and_download_youtube_dl(Dependencies_folder)
  MANAGER.update_dylibs_with_path(Dependencies_folder)
  MANAGER.add_all_needed_scripts(Dependencies_folder)
  MANAGER.add_build_number_script(Info_plist_path)
end

if ARGV.count == 0
  puts "Available Commands:".green
  puts "\n Usage: ruby init.rb 0"
  puts "\n 0 => run all scripts\n"
  puts " 1 => install all tool that needs\n"
  puts " 2 => integrate all dylibs and scripts\n"
  puts " 3 => fetching dependencies repos\n"
  puts " 4 => updating dependencies repos\n"
  puts " 5 => parsing doc to generated mpv commands\n"
  puts " 6 => integrate doc types\n"
  # parse_doc(Dependencies_folder)
  # integrate_project_with_dylibs_and_script
  MANAGER.update_dylibs_with_path(Dependencies_folder)
  MANAGER.add_all_needed_scripts(Dependencies_folder)
else
  ARGV.each do |cmd|
    if cmd == "0"
      InstallUtils.install_tools(Dependencies_folder)
      integrate_doc_types(Info_plist_path, assets_path, "psd/path")
      parse_doc(Dependencies_folder)
      fetch_sub_repos(cartfile_path, Dependencies_folder)
      integrate_project_with_dylibs_and_script
    elsif cmd == "1"
      InstallUtils.install_tools(Dependencies_folder)
    elsif cmd == "2"
      integrate_project_with_dylibs_and_script
    elsif cmd == "3"
      fetch_sub_repos(cartfile_path, Dependencies_folder)
    elsif cmd == "4"
      update_sub_repos(Dependencies_folder)
    elsif cmd == "5"
      parse_doc(Dependencies_folder)
    elsif cmd == "6"
      integrate_doc_types(Info_plist_path, assets_path, "psd/path")
    end
  end
  puts "🎉🎉🎉 done"
end
