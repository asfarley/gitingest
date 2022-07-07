require 'time'
require 'FileUtils'
require 'optparse'

def is_datestring(str)
	%w(2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030).any?{ |y| (str.include? y )&& (!str.downcase.include? "vs") }
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
	select_datestring(File.basename(path).split('_'))
end

def version_from_path(path)
	major_version = path.split('_')[1].split('x')[0].to_f
	minor_version = path.split('_')[1].split('x')[1].to_f
	version_number = major_version + minor_version/100.0
end

def trailing_number_from_path(path)
	fields = File.basename(path).split('_')
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

def extract_zipfile(path, output)
	puts "Command: 7z x #{path} -o#{output}"
	`7z x #{path} -o#{output}"` 
	puts "After extract_zipfile. $? is #{$?}"
	puts "Done extract_zipfile"
end

def extract_tgz(path, output)
	puts "Command: tar xf #{path} -C #{output}"
	`tar xf #{path} -C #{output}` 
	puts "After extract_tgz. $? is #{$?}"
	puts "Done extract_tgz"
end

def clear_repository_folder(output)
	FileUtils.rm_rf Dir.glob("#{output}/*")
end

def commit_project(zf, output)
	puts "commit_project:string_to_datetime"
	datestr = datestring_from_path(zf)
	datetime = string_to_datetime(datestr)
	command_string = "cd #{output} && git add --all && git commit -m \"History commit: #{zf}\" --date \"#{datetime.to_s}\""
	`#{command_string}`
	puts "Done commit_project"
end

def confirm_output_folder_empty(dir)
	output_folder_contents = Dir.glob("#{dir}/*")
	if(output_folder_contents.length != 0)
		puts "Project working folder (#{dir}) is not empty; contents must be deleted manually before using this script."
		abort
	end
end

def extract_commit_cleanup(zf, output)
	puts "Clearing output folder..."
	clear_repository_folder(output)
	confirm_output_folder_empty(output)
	puts "Extracting #{zf}..."
	ext = File.extname(zf)
	if ext == ".7z"
		extract_zipfile(zf, output)	
	elsif ext == ".tgz"
		extract_tgz(zf, output)	
	end
	
	puts "Committing..."
	commit_project(zf, output)
	puts "Done."
end

if __FILE__==$0
	options = {}
	OptionParser.new do |opt|
	  opt.on('--zipfiles ZIPFILES') { |o| options[:zipfiles] = o }
	  opt.on('--output OUTPUT') { |o| options[:output] = o }
	end.parse!

	# this will only run if the script was the main, not load'd or require'd
	zipfiles = []
	File.readlines(options[:zipfiles]).each do |line|
		line_sanitized = line.delete("\n").delete("\r")
		zipfiles.push(line_sanitized)
	end

	puts "Processing #{zipfiles.count} files"

	szf = sort_paths_by_filename_version(zipfiles)
	szf.each{ |zf| extract_commit_cleanup(zf, options[:output]) }
end