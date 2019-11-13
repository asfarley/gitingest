require 'time'
require 'FileUtils'

def is_datestring(str)
 %w(2012 2013 2014 2015 2016 2017 2018 2019).any?{ |y| str.include? y }
end

def select_datestring(parts)
 datestrings = parts.select{ |p| is_datestring(p) }
 if datestrings.nil? or datestrings.count == 0
	puts "No datestring: #{parts}"
	abort
 end
 datestrings.first.chomp ".7z"
end
 
def datestring_from_path(path)
 select_datestring(path.split('_'))
end

def version_from_path(path)
 major_version = path.split('_')[1].split('x')[0].to_f
 minor_version = path.split('_')[1].split('x')[1].to_f
 version_number = major_version + minor_version/100.0
end

def trailing_number_from_path(path)
  fields = path.split('_')
  if fields.count <= 3 
	return 0.0
  elsif fields.count >= 4
	return fields[3].to_f
  else
	return 0.0
  end
end

def string_to_datetime(datestr)
 Time.strptime(datestr, "%Y%m%d")
end

def sort_paths_by_filename_date(zipfiles)
	zipfiles.sort_by{ |zf| string_to_datetime(datestring_from_path(zf)) }
end

def sort_paths_by_filename_version(zipfiles)
	zipfiles.sort_by{ |zf| [version_from_path(zf), string_to_datetime(datestring_from_path(zf)), trailing_number_from_path(zf)] }
end

def extract_zipfile(path)
 puts "Command: 7z x #{path} -oC:\\Vital-Sim\\VSLS"
 `7z x #{path} -oC:\\Vital-Sim\\VSLS` 
end

def clear_repository_folder
 FileUtils.rm_rf Dir.glob("./VSLS/*")
end

def commit_project(zf)
	datestr = datestring_from_path(zf)
	datetime = string_to_datetime(datestr)
	command_string = "cd VSLS && git add --all && git commit -m \"History commit: #{zf}\" --date \"#{datetime.to_s}\""
	`#{command_string}`
end

def restore_gitignore
 FileUtils.cp "./.gitignore", "./VSLS/.gitignore"
end

def extract_commit_cleanup(zf)
 puts "Extracting #{zf}..."
 extract_zipfile(zf)
 puts "Restoring gitignore..."
 restore_gitignore
 puts "Committing..."
 commit_project(zf)
 puts "Clearing..."
 clear_repository_folder
 puts "Done."
end

zipfiles = []
File.readlines('./zipfiles.txt').each do |line|
    line_sanitized = line.delete("\n").delete("\r")
	zipfiles.push(line_sanitized)
end

puts "Processing #{zipfiles.count} files"

szf = sort_paths_by_filename_version(zipfiles)
szf.each{ |zf| extract_commit_cleanup(zf) }