#!/usr/bin/env ruby
require 'fileutils'

def copy_include(dependencies_folder)
  mpv_include_folder = "#{`brew --prefix mpv`.chomp}/include/mpv"
  mpv_headers = ["client.h", "opengl_cb.h"]
  ffmpeg_include_folder = "#{`brew --prefix ffmpeg`.chomp}/include"
  include_folder =  "#{dependencies_folder}/include"
  mpv_include_folder_leaf = "#{include_folder}/mpv"

  rm_rf include_folder
  FileUtils.mkdir_p(mpv_include_folder_leaf,{})

  mpv_headers.each do |header|
    FileUtils.cp("#{mpv_include_folder}/#{header}", "#{mpv_include_folder_leaf}")
  end

  Dir["#{ffmpeg_include_folder}/*"].each do |folder|
    FileUtils.cp_r(folder,include_folder)
  end

end

def download_youtube_dl(dependencies_folder)
  executable_file =  "#{dependencies_folder}/executable/youtube-dl"
  if File.exist? executable_file
    puts "already got youtube-dl"
  else
    `curl -L https://yt-dl.org/downloads/latest/youtube-dl -o #{executable_file}`
  end
end

def linked_pip_framework(dependencies_folder)
  framework_folder =  "#{dependencies_folder}/framework"
  FileUtils.mkdir_p(framework_folder,{})
  rm_rf "#{framework_folder}/PIP.framework"
  system("sudo ln -s /System/Library/PrivateFrameworks/PIP.framework #{framework_folder}")
end

def copy_include_and_download_youtube_dl(dependencies_folder)
  copy_include(dependencies_folder)
  download_youtube_dl(dependencies_folder)
  linked_pip_framework(dependencies_folder)
end
