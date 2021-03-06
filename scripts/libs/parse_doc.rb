#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

DOC_URL = "https://mpv.io/manual/stable/"

class String
  def to_camel
    self.strip.gsub(/(-|\/|\s)(.)/) {|e| $2.upcase}
  end

  def uncapitalize
    self[0, 1].downcase + self[1..-1]
  end
end

def parse_doc(dependencies_folder)
  # doc = Nokogiri::HTML open(DOC_URL)
  project_dir = File.expand_path("..", dependencies_folder)
  doc = Nokogiri::HTML(open("#{project_dir}/scripts/libs/mpv.io.html"))
  preface = "// This file is auto-generated by Scripts/parse_doc.rb, do not modify! \n"
  preface += "// Generated at " + Time.now.strftime("%d/%m/%Y %H:%M") + "\n\n"

  deps = dependencies_folder
  generated_code_folder = File.join(deps, "generated")

  rm_rf generated_code_folder
  FileUtils.mkdir_p(generated_code_folder,{})

  # property
  property_list = doc.css '#property-list .docutils > dt > tt'

  File.open(File.join(generated_code_folder, 'MPVProperty.swift'), 'w') do |file|
    file.write "#{preface}"
    file.write "import Foundation\n\n"
    file.write "extension MPV {\n"
    file.write "\tpublic enum Property {\n"
    total_raw_value = "\t\t/** string value */\n\tvar rawValue: String {\n\t\tswitch self {\n"

    open_tag_name = ''
    open_tag_camel_name = ''
    tag_data = Array.new
    rawValue = ''

    property_list.each do |property|
      name = property.content
      camel_name = name.to_camel

      if (name.start_with? open_tag_name) and (open_tag_name != '')
        if name.include? '/'
          if (name.include? '/TYPE/') and (!name.include? 'N')
            func_name = name.gsub('/TYPE/', 'type').to_camel.gsub(/#{open_tag_camel_name}/,'').uncapitalize
            return_str = name.gsub('TYPE', '\(type)')
            tag_data.push "\t\t/** #{name} */\n"
            tag_data.push "\t\tcase #{func_name}(String)\n"
            rawValue += "\t\t\t\tcase let .#{func_name}(type): return \"#{return_str}\"\n"
          elsif name.include? 'N'
            if name.include? '/TYPE/N/'
              func_name = name.gsub('/TYPE/N/', '/type/N/').to_camel.gsub(/#{open_tag_camel_name}/,'').uncapitalize
              return_str = name.gsub('N', '\(n)').gsub('TYPE', '\(type)')
              tag_data.push "\t\t/** #{name} */\n"
              tag_data.push "\t\tcase #{func_name}(String, Int)\n"
              rawValue += "\t\t\t\tcase let .#{func_name}(type, n): return \"#{return_str}\"\n"
            else
              func_name = name.to_camel.gsub(/#{open_tag_camel_name}/,'').uncapitalize
              return_str = name.gsub('N', '\(n)')
              tag_data.push "\t\t/** #{name} */\n"
              tag_data.push "\t\tcase #{func_name}(Int)\n"
              rawValue += "\t\t\t\tcase let .#{func_name}(n): return \"#{return_str}\"\n"
            end
          elsif name.include? '<name>'
            func_name = name.gsub('/<name>', '').to_camel.gsub(/#{open_tag_camel_name}/,'').uncapitalize
            return_str = name.gsub('<name>', '\(name)')
            tag_data.push "\t\t/** #{name} */\n"
            tag_data.push "\t\tcase #{func_name}(String)\n"
            rawValue += "\t\t\t\tcase let .#{func_name}(name): return \"#{return_str}\"\n"
          elsif not name.match(/<.+?>/)
            c_name = camel_name.gsub(/#{open_tag_camel_name}/,'').uncapitalize
            tag_data.push "\t\t/** #{name} */\n"
            tag_data.push "\t\tcase #{c_name}\n"
            rawValue += "\t\t\t\tcase .#{c_name}: return \"#{name}\"\n"
          end
        end
      else
        if (tag_data.count == 0) and (open_tag_name != '') and (open_tag_camel_name != '')
          comment_line = "\t\t/** #{open_tag_name} */\n"
          case_line = ""
          if open_tag_name.include? '/'
            if open_tag_name.include? 'N'
              if open_tag_name.include? '/TYPE/'
                func_name = open_tag_name.gsub('/TYPE/', '').to_camel.gsub(/#{open_tag_camel_name}/,'').uncapitalize
                return_str = open_tag_name.gsub('N', '\(n)').gsub('TYPE', '\(type)')
                case_line = "\t\tcase #{func_name}(Int, String)\n"
                total_raw_value += "\t\t\tcase let .#{func_name}(n, type): return \"#{return_str}\"\n"
              else
                func_name = open_tag_name.to_camel.gsub(/#{open_tag_camel_name}/,'').uncapitalize
                return_str = open_tag_name.gsub('N', '\(n)')
                case_line = "\t\tcase #{func_name}(Int)\n"
                total_raw_value += "\t\t\tcase let .#{func_name}(n): return \"#{return_str}\"\n"
              end

            elsif open_tag_name.include? '<name>'
              func_name = open_tag_name.gsub('/<name>', '').to_camel.gsub(/#{open_tag_camel_name}/,'').uncapitalize
              return_str = open_tag_name.gsub('<name>', '\(name)')
              case_line = "\t\tcase #{func_name}(String)\n"
              total_raw_value += "\t\t\tcase let .#{func_name}(name): return \"#{return_str}\"\n"
            elsif not open_tag_name.match(/<.+?>/)
              c_name = camel_name.gsub(/#{open_tag_camel_name}/,'').uncapitalize
              case_line = "\t\tcase #{c_name}\n"
              total_raw_value += "\t\t\tcase .#{c_name}: return \"#{open_tag_name}\"\n"
            end
          else
            case_line = "\t\tcase #{open_tag_camel_name}\n"
            total_raw_value += "\t\t\tcase .#{open_tag_camel_name}: return \"#{open_tag_name}\"\n"
          end
          file.write comment_line
          file.write case_line

        elsif tag_data.count > 0 and (open_tag_name != '') and (open_tag_camel_name != '')
          case_name = open_tag_camel_name.gsub('<name>', '')
          enum_name = case_name.capitalize
          tag_data = tag_data.unshift "\t\tcase #{case_name}\n"
          rawValue += "\t\t\t\tcase .#{case_name}: return \"#{open_tag_name}\"\n"
          file.write "\t\t/** #{open_tag_name} */\n"
          file.write "\t\tcase #{case_name}(#{enum_name})\n"
          total_raw_value += "\t\t\tcase let .#{case_name}(value): return value.rawValue\n"
          file.write "\n\t\tpublic enum #{enum_name} {\n"
          tag_data.each do |line|
            file.write "\t\t#{line}"
          end
          rawValue += "\t\t\t\t}\n\t\t\t}\n"
          file.write "#{rawValue}"
          file.write "\t\t}\n"
        end
        tag_data = Array.new
        open_tag_name = name
        open_tag_camel_name = camel_name
        rawValue = "\t\t\t/** string value */\n\t\t\tvar rawValue: String {\n\t\t\t\tswitch self {\n"
      end
    end
    total_raw_value += "\t\t\t}\n\t\t}\n"
    file.write "#{total_raw_value}"
    file.write "\t}\n}\n"
  end

  # option
  option_sections = doc.css '#options > .section'

  exist_op = []

  File.open(File.join(generated_code_folder, 'MPVOption.swift'), 'w') do |file|
    file.write "#{preface}"
    file.write "import Foundation\n\n"
    file.write "extension MPV {\n"
    file.write "\tpublic enum Option {\n"
    total_raw_value = "\n\t\tpublic var rawValue: String {\n\t\t\tswitch self {\n"
    total_enum_string = ""
    total_case_string = ""

    option_sections.each do |section|
      section_title = section.at_css 'h2'
      section_title_camel = section_title.content.to_camel
      if section_title_camel == 'TV' then next end  # jump tv
      case_name = section_title_camel.uncapitalize
      total_raw_value += "\t\t\tcase let .#{case_name}(item): return item.rawValue\n"
      total_case_string += "\t\tcase #{case_name}(#{section_title_camel})\n"
      total_enum_string += "\t\tpublic enum #{section_title_camel}: String {\n"
      option_list = section.xpath './dl/dt/tt'
      option_list.each do |option|
        # puts option
        op_format = option.content
        op_format.gsub(/<(.+?)>/) {|m| $0.gsub(',', '$')}  # remove ',' temporarily
        op_format.split(',').each do |f|
          f.gsub('$', ',')  # add back ','
          match = f.match(/--(.+?)(=|\Z)/)
          if match.nil? then next end
          op_name = match[1]
          if exist_op.include?(op_name) or op_name.include?('...') then next end
          total_enum_string += "\t\t\t/** #{f} */\n"
          total_enum_string += "\t\t\tcase #{op_name.to_camel}"
          if op_name.to_camel != op_name
            total_enum_string += " = \"#{op_name}\"\n"
          else
            total_enum_string += "\n"
          end
          exist_op << op_name
        end
      end
      total_enum_string += "\t\t}\n\n"
    end
    total_raw_value += "\t\t\t}\n\t\t}\n"
    file.write total_case_string
    file.write total_raw_value
    file.write total_enum_string
    file.write "\t}\n}\n"
  end

  # command
  # command_list = doc.css '#list-of-input-commands > .docutils > dt > tt, #input-commands-that-are-possibly-subject-to-change > .docutils > dt > tt'
  #
  # File.open(File.join(generated_code_folder, 'MPVCommand.swift'), 'w') do |file|
  #   file.write "#{preface}"
  #   file.write "import Foundation\n\n"
  #   file.write "public enum MPVCommand: String {\n"
  #   command_list.each do |command|
  #     format = command.content
  #     name = format.split(' ')[0]
  #     file.write "\t/** #{format} */\n"
  #     file.write "\tcase #{name.to_camel}"
  #     if name.to_camel != name
  #       file.write " = \"#{name}\"\n"
  #     else
  #       file.write "\n"
  #     end
  #   end
  #   file.write "}\n"
  # end
end
