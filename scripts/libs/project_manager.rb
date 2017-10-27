#!/usr/bin/env ruby
require 'xcodeproj'
require_relative "extensions.rb"

class ProjectManager
  attr_accessor :project, :target, :dylibs_group , :framework_group,
  :executable_group, :config_group, :lua_group, :generated_group, :dsym_group, :oc_group

  def initialize(params = {})
      project_path = params.fetch(:project)
      target_name = params.fetch(:target)
      if project_path == nil
        abort("no project found")
      end
      if target_name == nil
        abort("no target name found")
      end
      @project = Xcodeproj::Project.open(project_path)
      @target = project.find_target_with_name(target_name)
      if target == nil
        abort("not found target named: #{Xcodeproj::Project.TargetName}")
      end
      dependencies_group = project.find_or_create_group_with_name(Xcodeproj::Project.DependenciesName)
      @framework_group = dependencies_group.find_or_create_group_with_name("frameworks")
      @dylibs_group = dependencies_group.find_or_create_group_with_name("dylibs")
      @executable_group = dependencies_group.find_or_create_group_with_name("executable")
      @config_group = dependencies_group.find_or_create_group_with_name("config")
      @lua_group = dependencies_group.find_or_create_group_with_name("lua")
      @generated_group = dependencies_group.find_or_create_group_with_name("generated")
      @dsym_group = dependencies_group.find_or_create_group_with_name("dsym")
      @oc_group = dependencies_group.find_or_create_group_with_name("oc")
  end

  def save
    project.save()
  end

  def update_dylibs_with_path(dependency_dir)
    lib_dependencies_dir = "#{dependency_dir}/lib"
    framework_dependencies_dir = "#{dependency_dir}/framework"
    carthage_build_dir = "#{dependency_dir}/Carthage/Build/Mac"
    executable_dependencies_dir = "#{dependency_dir}/executable"
    generated_code_dir = "#{dependency_dir}/generated"
    include_dir = "#{dependency_dir}/include"
    # reset
    framework_group.clear
    dylibs_group.clear

    dylibs_files = Dir["#{lib_dependencies_dir}/*.dylib"]
    dylibs_reference = Array.new
    dylibs_files.each do |file|
      real_path = File.realpath(file)
      if real_path == file
        ref = dylibs_group.new_reference(file)
        dylibs_reference.push(ref)
      end
    end
    target.redefine_copy_files_build_phase_with_name("📦 [Copy Dylibs]", dylibs_reference,
       Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:frameworks])
    linked_framworks_and_libraries(framework_dependencies_dir, carthage_build_dir)
    save
  end

  def linked_framworks_and_libraries(framework_dependencies_dir, carthage_build_dir)
    target.frameworks_build_phases.clear
    frameworks = Dir["#{`brew --prefix mpv`.chomp}/lib/*.dylib"]
    frameworks += Dir["#{`brew --prefix ffmpeg`.chomp}/lib/*.dylib"]
    # mpv and ffmpeg frameworks
    frameworks.each do |framework|
      file_name = File.basename(framework)
      if file_name.start_with?("libpostproc")
        next
      end
      real_path = File.realpath(framework)
      real_basename = File.basename(real_path)
      if real_basename == file_name
        ref = dylibs_group.new_reference(framework)
        target.frameworks_build_phases.add_file_reference(ref)
      end
    end
    #pip framework
    pip_framework = "#{framework_dependencies_dir}/PIP.framework"
    real_path = File.realpath(pip_framework)
    ref = framework_group.new_reference(pip_framework)
    target.frameworks_build_phases.add_file_reference(ref)

    build_frameworks = Dir["#{carthage_build_dir}/*.framework"]
    build_frameworks_paths  = Array.new
    build_frameworks.each do |framework|
      ref = framework_group.new_reference(framework)
      target.frameworks_build_phases.add_file_reference(ref)
      basename = File.basename(framework)
      path = "$(SRCROOT)/dependencies/Carthage/Build/Mac/#{basename}"
      build_frameworks_paths.push(path)
    end
    target.redefine_copy_carthage_framework_phase_with_name("📦 [Copy Framework]", build_frameworks_paths)

    build_frameworks_dsym = Dir["#{carthage_build_dir}/*.dSYM"]

    dsym_group.clear
    puts "dsym_group: #{dsym_group}"
    reference = Array.new
    build_frameworks_dsym.each do |file|
      ref = dsym_group.new_reference(file)
      reference.push(ref)
    end
    target.redefine_copy_files_build_phase_with_name("📦 [Copy Framework dSYM]", reference,
      Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:products_directory])
  end

  def add_generated_code(dependencies_folder)
    generated_group.clear
    files = Dir["#{dependencies_folder}/generated/*.swift"]
    reference = Array.new
    files.each do |file|
      ref = generated_group.new_reference(file)
      reference.push(ref)
    end
    target.add_file_references(reference)
  end

  def add_oc_code(dependencies_folder)
    oc_group.clear
    files = Dir["#{dependencies_folder}/oc/*.h"]
    files += Dir["#{dependencies_folder}/oc/*.m"]
    reference = Array.new
    files.each do |file|
      ref = oc_group.new_reference(file)
      reference.push(ref)
    end
    target.add_file_references(reference)
  end

  def add_all_needed_scripts(dependencies_folder)
    add_generated_code(dependencies_folder)
    add_oc_code(dependencies_folder)
    add_copy_symbolic_links()
    add_copy_executables(dependencies_folder)
    add_copy_configs(dependencies_folder)
    add_lua_script(dependencies_folder)
    save
  end

  def add_build_number_script(info_plist)
    script =
    '''import Foundation
enum Keys: String {
    case build = "CFBundleVersion"
    case infoPlist = "INFOPLIST_FILE"
    case user = "USER"
    case configuration = "CONFIGURATION"
    case buildNumberInfo = "AutomaticBuildNumber"
    case release = "Release"
}
guard let infoPath = ProcessInfo.processInfo.environment[Keys.infoPlist.rawValue],
let user = ProcessInfo.processInfo.environment[Keys.user.rawValue],
let configuration = ProcessInfo.processInfo.environment[Keys.configuration.rawValue] else { exit(0) }
var userInfo: [String : Any] = [:]
if let info = NSDictionary(contentsOfFile: infoPath) as? [String : Any] { userInfo = info }
var buildNumberInfo: [String : Int] = [:]
if let value = userInfo[Keys.buildNumberInfo.rawValue] as? [String : Int] {
buildNumberInfo = value
}
var old = buildNumberInfo[user] ?? 0
old += 1
buildNumberInfo[user] = old
if configuration == Keys.release.rawValue {
let total = buildNumberInfo.values.reduce(0, +)
userInfo[Keys.build.rawValue] = total
}
userInfo[Keys.buildNumberInfo.rawValue] = buildNumberInfo
(userInfo as NSDictionary).write(toFile: infoPath, atomically: true)'''
    target.redefine_shell_script_build_phase_with_name("📦 [Auto Add Xcode Build]", script, "/usr/bin/env xcrun -sdk macosx swift")
    save
  end

  def add_lua_script(dependencies_folder)
    files = Dir["#{dependencies_folder}/lua/*.lua"]
    reference = Array.new
    files.each do |file|
      ref = lua_group.new_reference(file)
      reference.push(ref)
    end
    target.redefine_copy_files_build_phase_with_name("📦 [Copy Lua Scripts]", reference,
      Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:resources])
  end

  def add_copy_configs(dependencies_folder)
    config_group.clear
    config_files = Dir["#{dependencies_folder}/config/*.conf"]
    config_reference = Array.new
    config_files.each do |file|
      ref = config_group.new_reference(file)
      config_reference.push(ref)
    end
    target.redefine_copy_files_build_phase_with_name("📦 [Copy Config]", config_reference,
      Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:resources], "config")
  end

  def add_copy_executables(dependencies_folder)
    executable_group.clear
    references = Array.new
    file = "#{dependencies_folder}/executable/youtube-dl"
    ref = executable_group.new_reference(file)
    references.push(ref)
    target.redefine_copy_files_build_phase_with_name("📦 [Copy Executable]",
      references, Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:executables])
  end

  def add_copy_symbolic_links()
    copy_symbolic_links =
'''echo "Copy symlinks:"
for file in "${SRCROOT}/deps/lib/"*.dylib; do
  if [[ -h "$file" ]]; then
    cp -R $file "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/$(basename $file)"
  fi
done'''
    target.redefine_shell_script_build_phase_with_name("📦 [Copy Dylib Symlinks]", copy_symbolic_links)
  end
end
