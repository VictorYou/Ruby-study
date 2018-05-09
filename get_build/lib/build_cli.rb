require 'build_info'
require 'optparse'
require 'build_all'
require 'build_aborted'
require 'feature_check'
require 'log'

class BuildCLI
  include ReadSaveFile

  def initialize
    @option_parser = OptionParser.new do |opt|
      opt.on("-jNAME", "--jenkins=NAME", "jenkins server file") do |v|
        @options[:jenkins] = v
      end
      opt.on("-JNAME", "--jobs=NAME", "jenkins jobs") do |v|
        @options[:jobs] = v
      end
      opt.on("-dNAME", "--date=NAME", "start date") do |v|
        @options[:start_date] = v
      end
      opt.on("-S", "--start_analysis", "start date for analysis") do |v|
        @options[:start_date_analysis] = true
      end
      opt.on("-sNAME", "--sonar=NAME", "sonar projects") do |v|
        @options[:sonar_projects] = v
      end
      opt.on("-lNAME", "--log=NAME", "log level") do |v|
        @options[:log_level] = v
      end
      opt.on("-a", "--all", "all builds") do |v|
        @options[:all] = true
      end
      opt.on("-A", "--aborted", "aborted builds") do |v|
        @options[:aborted] = true
      end
    end
    @options = {}
    @start_time = Time.now
    @jenkins_job_list = []
    @jenkins_server_list = []
    @sonar_project_list = []
  end

  def run(argv)
    parse_args argv
    $log_level = @options[:log_level]? @options[:log_level].upcase: 'INFO'
    FeatureCheck.new.set_feature
    if @jenkins_server_list.size > 0 and @jenkins_job_list.size > 0
      build_info = AllBuildInfo.new(@jenkins_server_list, @jenkins_job_list)
      build_info.get_build_info
      save_file 'builds_all', build_info.all_build if @options[:all]
      save_file 'builds_starting', build_info.build_starting(@options[:start_date]) if @options[:start_date]
      save_file 'builds_starting_analysis', build_info.build_starting_for_analysis if @options[:start_date_analysis]
      save_file 'builds_aborted', build_info.aborted_build if @options[:aborted]
    end
    if @sonar_project_list.size > 0
      log "#{__FILE__}, #{__LINE__} #{@sonar_project_list.inspect}", 'debug'
      sonar_build_info = AllSonarBuildInfo.new(@sonar_project_list)
      sonar_build_info.get_build_info
      save_file 'sonar_builds_ut', sonar_build_info.all_build
    end
    print_time_consumption
  end

  def parse_args(argv)
    @option_parser.parse argv
    if @options[:jenkins] && @options[:jobs]
      @jenkins_server_list = read (@options[:jenkins])
      @jenkins_job_list = read (@options[:jobs])
      return
    end
    if @options[:sonar_projects]
      @sonar_project_list = read (@options[:sonar_projects])
      return
    end
    p "either jenkins + jobs or sonar projects are needed"
    exit 1
  end  

  def get_aborted_builds
    build_aborted = AllBuildInfo.new(@jenkins_server_list, @jenkins_job_list)
    build_aborted.save_aborted_build
    build_aborted.data
  end

  def get_all_builds
    all_build = AllBuildInfo.new(@jenkins_server_list, @jenkins_job_list)
    all_build.save_all_id
    all_build.data
  end

  def save_file(file, hash_list)
    # save the builds to a file
    log "save the builds to a file: #{file}", 'info'
     
    save(file, hash_list) if file && hash_list
  end

  def print_time_consumption
    p "time consumption: #{Time.now - @start_time}"
  end
end

