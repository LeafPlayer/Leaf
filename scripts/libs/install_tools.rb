#!/usr/bin/env ruby
class InstallUtils
  def self.info(msg)
    puts "[Intstall Tool]: #{msg}"
  end
  def self.brew_prefix(cmd)
    result = `brew --prefix #{cmd}`.chomp
    dir = File.directory?(result)
    return File.directory?(result)
  end

  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      }
    end
    return nil
  end

  def self.install_tools(dependencies_folder)
    if which('brew') == nil
      info("installing brew...")
      `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1`
    end

    if which('mpv') == nil
      info("installing mpv...")
      `brew install mpv --with-uchardet`
    end

    brew_install_libs = ["libbluray", "libdvdnav", "libdvdcss"]
    brew_install_libs.each do |lib|
      if brew_prefix(lib) == false
        info "installing #{lib}"
        `brew install #{lib}`
      end
    end

    if which('pip') == nil
      info("installing pip...")
      `sudo easy_install pip`
    end

    if which('punic') == nil
      info("installing punic...")
      folder = "#{dependencies_folder}/tool"
      `git clone https://github.com/CodeEagle/punic.git #{folder}`
      `python #{folder}/setup.py`
      `pip install -e #{folder}`
    end

    if which('carthage') == nil
      info("installing carthage...")
      `brew install carthage`
    end

    if which('swiftformat') == nil
      info("installing swiftformat...")
      `brew install swiftformat`
    end
  end
end
