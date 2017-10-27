#!/usr/bin/env ruby
require 'xcodeproj'
class Array
  def remove(object)
    rm_index = index(object)
    if rm_index != nil
      delete_at(rm_index)
    end
  end
end

class Xcodeproj::Project

  def self.DependenciesName
    return "Dependencies"
  end

  def self.TargetName
    return "Leaf"
  end

  def find_target_with_name(name)
      targets.each do |_target|
        if _target.name == name
          return _target
        end
      end
      return nil
  end

  def find_or_create_group_with_name(name)
    target_group = {}
    find = false

    groups.each do |group|
      if group.display_name == name
        target_group = group
        find = true
        break
      end
    end

    if find == false
      target_group = new_group(name)
    end
    return target_group
  end

end
class Xcodeproj::Project::Object::PBXNativeTarget

  def remove_build_phase_with_name(name)
    build_phases.each do |phase|
      if phase.display_name == name
        build_phases.remove(phase)
        break
      end
    end
  end

  def redefine_copy_files_build_phase_with_name(name, file_refs, dst_subfolder_spec, sub_path = "")
    remove_build_phase_with_name(name)
    phase = new_copy_files_build_phase(name)
    phase.dst_subfolder_spec = dst_subfolder_spec
    phase.dst_path = sub_path
    file_refs.each do |ref|
      build_file = phase.add_file_reference(ref, true)
      build_file.settings = { "ATTRIBUTES" => ["CodeSignOnCopy"] }
    end
  end

  def redefine_shell_script_build_phase_with_name(name, script, shell_path = "/bin/sh")
    remove_build_phase_with_name(name)
    phase = new_shell_script_build_phase(name)
    phase.shell_path = shell_path
    phase.shell_script = script
  end

  def redefine_copy_carthage_framework_phase_with_name(name, files)
    remove_build_phase_with_name(name)
    phase = new_shell_script_build_phase(name)
    phase.shell_path = "/bin/sh"
    phase.shell_script = "/usr/local/bin/carthage copy-frameworks"
    phase.input_paths = files
  end

end

class Xcodeproj::Project::Object::AbstractTarget
  def add_system_library_tbd(names)
     Array(names).each do |name|
        path = "usr/lib/lib#{name}.tbd"
        files = project.frameworks_group.files
        unless reference = files.find { |ref| ref.path == path }
           reference = project.frameworks_group.new_file(path, :sdk_root)
        end
        frameworks_build_phase.add_file_reference(reference, true)
        reference
     end
  end
end

class Xcodeproj::Project::Object::PBXGroup
  def delete_group(group)
    children.remove(group)
  end

  def delete_group_name(name)
    group = find_or_create_group_with_name(name)
    delete_group(group)
  end

  def find_or_create_group_with_name(name)
    target_group = {}
    find = false

    children.each do |group|
      if group.display_name == name
        target_group = group
        find = true
        break
      end
    end

    if find == false
      target_group = new_group(name)
    end
    return target_group
  end
end
