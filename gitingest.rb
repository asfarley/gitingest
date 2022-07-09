require 'time'
require 'fileutils'
require 'optparse'
require 'debug'

# Cross-platform way of finding an executable in the $PATH.
#
#   which('ruby') #=> /usr/bin/ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

def is_datestring(str)
	str.match(/\A[12][0-9][0-9][0-9]/)
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
	win_path = path.gsub('/', '\\') 
	win_output = output.gsub('/', '\\') 
	puts "Command: 7z x #{win_path} -o#{win_output}"
	`7z x #{win_path} -o#{win_output}"` 
end

def extract_tgz(path, output)
	win_path = path.gsub('/', '\\') 
	win_output = output.gsub('/', '\\') 
	puts "Command: tar xf #{path} -C #{win_output}"
	`tar xf #{path} -C #{win_output}` 
end

def clear_repository_folder(output)
	FileUtils.rm_rf Dir.glob("#{output}/*")
end

def commit_project(zf, output)
	datestr = datestring_from_path(zf)
	datetime = string_to_datetime(datestr)
	command_string = "cd #{output} && git add --all && git commit -m \"History commit: #{zf}\" --date \"#{datetime.to_s}\""
	`#{command_string}`
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
	_7z_path = which('7z')
	if _7z_path.nil? 
		puts "This script requires 7z, but it was not found in the path."
		return
	end
	
	options = {}
	OptionParser.new do |opt|
	  opt.on('--input INPUT') { |o| options[:input] = o }
	  opt.on('--output OUTPUT') { |o| options[:output] = o }
	end.parse!

	input_path = options[:input].gsub(File::ALT_SEPARATOR, File::SEPARATOR)	
	output_path = options[:output].gsub(File::ALT_SEPARATOR, File::SEPARATOR)	

	zipfiles = Dir[input_path + "/*"]
	puts "Processing #{zipfiles.count} files"

	szf = sort_paths_by_filename_version(zipfiles)
	szf.each{ |zf| extract_commit_cleanup(zf, output_path) }
end