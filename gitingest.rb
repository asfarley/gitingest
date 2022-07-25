#!/usr/bin/env ruby

require 'fileutils'
require 'ostruct'
require 'optparse'
require 'time'
require 'debug'

module GitIngestUtils
  def status(msg, type=:info, indent=0, io=$stderr)
    case type
    when :error
      msg = red(msg)
    when :success
      msg = green(msg)
    when :warning
      msg = yellow(msg)
    when :info
      msg = blue(msg)
    when :speak
      msg = blue(say(msg))
    end

    io.puts "%s %s" % ["  " * indent, msg]
  end

  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end
  def red(text); colorize(text, 31); end
  def green(text); colorize(text, 32); end
  def blue(text); colorize(text, 34); end
  def yellow(text); colorize(text, 33); end
end

class GitIngest
  include GitIngestUtils

  ::Version = [1,0,0]

  attr_accessor :options

  def initialize(args)
    @options = OpenStruct.new

    opt_parser = OptionParser.new do |opt|
      opt.banner = "Usage: #{$0} [OPTION]... INPUT_PATH..."

      opt.on('--output OUTPUT') { |o| options.output = o }

      opt.on_tail("-h","--help","Print usage information.") do
        $stderr.puts opt_parser
        exit 0
      end

      opt.on_tail("--version", "Show version") do
        puts ::Version.join('.')
        exit 0
      end
    end

    begin 
      opt_parser.parse!
    rescue OptionParser::InvalidOption => e
      $stderr.puts "Specified #{e}"
      $stderr.puts opt_parser
      exit 64 # EX_USAGE
    end

    if ARGV.size < 1
      $stderr.puts "No input path provided."
      $stderr.puts opt_parser
      exit 64 # EX_USAGE
    end

    @input_paths = ARGV
    @validation_errors = {}
  end

  def injest!
    _7z_path = which('7z')
    if _7z_path.nil? 
      status "This script requires 7z, but it was not found in the path.", :error
      return
    end
    
    @input_paths.each do |input_path|
      input_standardized = input_path.gsub(File::ALT_SEPARATOR, File::SEPARATOR) 
	  puts "input_standardized: " + input_standardized
	  
      output_path = options.output.gsub(File::ALT_SEPARATOR, File::SEPARATOR) 

      zipfiles = Dir[input_standardized + "/*"]
      status "Processing #{zipfiles.count} files", :info

      szf = sort_paths_by_filename_version(zipfiles)
      szf.each{ |zf| extract_commit_cleanup(zf, output_path) }
    end
  end

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
      status "No datestring: #{parts}", :error
      abort
    end
    datestrings.first.chomp ".7z"
  end
   
  def datestring_from_path(path)
    select_datestring(File.basename(path).split('_'))
  end

  def version_from_path(path)
  puts "Path: " + path
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
    status "Command: 7z x #{win_path} -o#{win_output}", :info
    `7z x #{win_path} -o#{win_output}"` 
  end

  def extract_tgz(path, output)
    win_path = path.gsub('/', '\\') 
    win_output = output.gsub('/', '\\') 
    status "Command: tar xf #{path} -C #{win_output}", :info
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
      status "Project working folder (#{dir}) is not empty; contents must be deleted manually before using this script.", :error
      abort
    end
  end

  def extract_commit_cleanup(zf, output)
    status "Clearing output folder...", :info
    clear_repository_folder(output)
    confirm_output_folder_empty(output)
    status "Extracting #{zf}...", :info, 1
    ext = File.extname(zf)
    if ext == ".7z"
      extract_zipfile(zf, output) 
    elsif ext == ".tgz"
      extract_tgz(zf, output) 
    end
    
    status "Committing...", :info, 1
    commit_project(zf, output)
    status "Done.", :info
  end
end

begin
  if $0 == __FILE__
    GitIngest.new(ARGV).injest!
  end
rescue Interrupt
  # Ctrl^C
  exit 130
rescue Errno::EPIPE
  # STDOUT was closed
  exit 74 # EX_IOERR
end
