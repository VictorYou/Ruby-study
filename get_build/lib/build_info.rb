require 'log'
require 'nokogiri'
require 'pathname'
require 'xml/mapping'
require 'json'
require 'fileutils'

# get gate build hash
# [
#   {'GATE-med_core3-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96'}]
#   }
# ]
#
module FlatHashList  
  # [{:jb=>[{}, {}]}] => [{}, {}]
  def flat_list
    @flat_list ||= []
    unless @flat_list.size > 0
      hash_list.each do |h|
        h.each_pair {|k, v| v.each {|h1| h1.merge!(:key=>k)}}
        @flat_list.concat h.values[0]
      end
    end  
    @flat_list
  end
end

class AllSonarBuildInfo
  include FlatHashList
  attr_reader :hash_list
  alias :all_build :flat_list

  def initialize(sonar_project_list)
    @sonar_project_list = sonar_project_list
    @hash_list = []
  end

  def get_build_info
    @hash_list.concat SonarBuildInfoList.new(:project_list=>@sonar_project_list).save_build_info.hash_list
  end
end

class AllBuildInfo
  include FlatHashList
  attr_reader :hash_list

  def initialize(jenkins_list, job_list)
    @jenkins_servers = jenkins_list
    @all_jobs = job_list
    @check_jobs = []
    @exp_jobs = []
    @hash_list = []
    
    # filter the gate jobs interested
    @zuul_project_list = @all_jobs.collect {|jb| /GATE-(.*)-component-build-deploy-test/ =~ jb ? $1: nil }
    @zuul_project_list.compact!
    @gate_jobs = @zuul_project_list.collect {|zp| 'GATE-' + zp + '-component-build-deploy-test'}
    (@all_jobs - @gate_jobs).each {|jb| 
      @check_jobs << jb if /^CHECK/ =~ jb 
      @exp_jobs << jb if /^EXP/ =~ jb 
    }
    @all_jobs.each do |jb|
      @hash_list << {jb => []}
    end
  end

  def get_build_info
    log "#{__FILE__}, #{__LINE__}, @gate_jobs: #{@gate_jobs.inspect}"
    @hash_list.concat JenkinsBuildInfoList.new(:jenkins_list=>@jenkins_servers, :job_list=>@check_jobs, :type=>'CHECK').save_build_info.hash_list
    @hash_list.concat JenkinsBuildInfoList.new(:jenkins_list=>@jenkins_servers, :job_list=>@exp_jobs, :type=>'EXP').save_build_info.hash_list
    log "#{__FILE__}, #{__LINE__}, @hash_list: #{@hash_list.inspect}"
    @hash_list.concat JenkinsBuildInfoList.new(:jenkins_list=>@jenkins_servers, :job_list=>@gate_jobs, :type=>'GATE').save_build_info.hash_list
    log "#{__FILE__}, #{__LINE__}, @hash_list: #{@hash_list.inspect}"
    
    log "#{__FILE__}, #{__LINE__}, @hash_list: #{@hash_list}"
    AllBuildInfo.filter_hash_list(@hash_list, @zuul_project_list)
    log "#{__FILE__}, #{__LINE__}, @hash_list: #{@hash_list}"
  end

  def self.filter_hash_list(hash_list, project_list)
    hash_list.each do |jh|
      jh.values[0].select! {|bh| project_list.include? bh[:zuul_project].gsub(/netact\//, '')}
    end
  end

end

class BuildInfoList
  attr_reader :hash_list

  def initialize(options={}, thread_number = 5)
    @max_thread_number = thread_number
    @mutex = Mutex.new
    @create_thread = {}
  end

  def parallel_save_build_info_1_job(options, &block)
    key = create_thread_key(options)
    @create_thread.merge!({key => true})
    each_build_id(options) { |build_id|
      break unless @create_thread[key]
      Thread.new { save_build_info_1_build(build_id, &block) }
      Thread.list[1..-1].each{|thr| thr.join} if Thread.list.size - 1 >= @max_thread_number
    }
    Thread.list[1..-1].each{|thr| thr.join}
  end

  def save_build_info_1_build(options={}, &block)
    begin
      info = block.call options if block.kind_of? Proc
      save_1_build_info options, info
    rescue Exception=>e  
      log "#{__FILE__}, #{__LINE__}, #{e.message}, #{e.backtrace.join("\n")}", 'debug'
      key = create_thread_key(options)
      @mutex.synchronize { @create_thread.merge!({key => false}) }
    end  
  end
end

module GitRepo
  Git_home_dir = "/home/#{ENV['USER']}/repo"
  Gerrit_repo_base = "ssh://#{ENV['USER']}@gerrite1.ext.net.nokia.com:8282/netact"

  def get_repo(project)
    FileUtils.mkdir_p Git_home_dir unless File.exists? Git_home_dir
    system(get_repo_cmd(project))
  end

  def get_repo_cmd (project)
    if repo_in_local? project
      "cd #{Git_home_dir}/#{project}; git pull"
    else
      "git clone #{Gerrit_repo_base}/#{project} #{Git_home_dir}/#{project}"
    end
  end

  def repo_in_local?(project)
    Dir[Git_home_dir + '/*'].collect { |dir| File.basename dir }.include? project
  end
end

module PomList
  def get_pom(path, poms=[])
    if directory? path
      dir(path).each {|p| get_pom p, poms}
    elsif /\/implementation\/pom.xml/ =~ path
      poms.delete_if {|p| File.dirname(p).start_with? File.dirname(path)}
      return poms if poms.select {|p| File.dirname(path).start_with? File.dirname(p)}.size > 0
      poms << path
    end
    poms
  end

  def pom_above(path)
    log "#{__FILE__}, #{__LINE__}: path: " << path, 'debug'
    if directory?(path) && File.exists?(path + '/pom.xml') 
      return path + '/pom.xml' 
    end  
    pom_above parent_path(path)
  end

  def directory?(path)
    Pathname.new(path).directory?
  end

  def parent_path(path)
    Pathname.new(path).dirname.to_s
  end

  def dir(path)
    Dir[path + '/*']
  end
end

class SonarBuildInfoList < BuildInfoList
  include FlatHashList
  include GitRepo
  include PomList

  attr_reader :hash_list
  attr_reader :poms


  def initialize(options, thread_number = 5)
    log "#{__FILE__}, #{__LINE__}:" << options.inspect, 'debug'
    @sonar_projects = options[:project_list]
    @hash_list = []
    
    @sonar_projects.each do |sp|
      @hash_list << {sp => []}
    end
    @poms = []
    @Ids = []
    super
  end

  def save_build_info
    @sonar_projects.each do |sp|
      parallel_save_build_info_1_job(:sp=>sp) {|options| get_build_info(options)}
    end  
    self
  end  

  def each_build_id(options, &block)
    ids(options[:sp]).each {|id| block.call options.merge(id)}
  end

  def create_thread_key(options={})
    options[:sp]
  end

  def save_1_build_info(options, info)
    sp = options[:sp]
    @mutex.synchronize { 
      @hash_list.find {|h| h.key? sp}[sp].concat info
    }
  end

  def get_build_info(options)
    info = SonarBuildInfo.new(options).build_info 
    log "#{__FILE__}, #{__LINE__}: info: " << info.inspect, 'debug'

    info.each do |h| 
      log "#{__FILE__}, #{__LINE__}: options: " << options.inspect, 'debug'

      # in case there are multiple paths found, check until TA is found
      ut_no_info = {:ut_no=>'NA'}
      log "#{__FILE__}, #{__LINE__}: search pattern: " << GitRepo::Git_home_dir + '/' + options[:sp] + '/**/' + h[:file], 'debug'
      Dir[GitRepo::Git_home_dir + '/' + options[:sp] + '/**/' + h[:file]].each do |full_path|
        log "#{__FILE__}, #{__LINE__}: full_path: " << full_path, 'debug'
        pom_file = pom_above(full_path)
        pom_id = get_id_from_pom pom_file
        next if pom_id[:gId].nil? or pom_id[:aId].nil?
        begin
          break if ut_no_info = SonarUTNoBuildInfo.new(options.merge(:file=>h[:file]).merge(pom_id)).build_info
        rescue Exception=>e
          log "#{__FILE__}, line: #{__LINE__}, #{e.message}, #{e.backtrace.join("\n")}, options: #{options.inspect}, file: #{h[:file]}, pom_id: #{pom_id.inspect}, pom_file: #{pom_file}", 'debug'
        end
      end  
      h.merge! ut_no_info
    end  
    info
  end

  def ids(project)
    log "#{__FILE__}, #{__LINE__}: project: " << project, 'debug'
    id_list = []
    poms = []
    get_repo(project)

    log "#{__FILE__}, #{__LINE__}: " << Git_home_dir + '/' + project, 'debug'
    poms = get_pom(Git_home_dir + '/' + project)
    log "#{__FILE__}, #{__LINE__}: poms: " << poms.inspect, 'debug'
    log "#{__FILE__}, #{__LINE__}: poms.size: " << poms.size.to_s, 'debug'
    poms.each {|pm| id_list << get_id_from_pom(pm)}
    log "#{__FILE__}, #{__LINE__}: id_list: " << id_list.inspect, 'debug'
    id_list
  end

  def get_id_from_pom(pom)
    log "#{__FILE__}, #{__LINE__}: pom: " << pom, 'debug'
    # do not break when there is no gId/aId in pom
    begin
      content = IO.read(pom)
      node = PomId.load_from_xml(REXML::Document.new(content).root)
      gId = node.gId.nil? ? node.parent[0].gId : node.gId
      aId = node.aId.nil? ? node.parent[0].aId : node.aId
      gId.gsub!(/\s/,'')
      aId.gsub!(/\s/,'')
      log "#{__FILE__}, #{__LINE__}: gId: " << gId << ", aId: " << aId, 'debug'
      {:gId=>gId, :aId=>aId}
    rescue Exception=>e
      log "#{__FILE__}, #{__LINE__}: " << e.message << e.backtrace.join("\n"), 'debug'
      {:gId=>nil, :aId=>nil}
    end
  end

end

class PomId
include XML::Mapping
text_node :aId, "artifactId", :default_value=>nil
text_node :gId, "groupId", :default_value=>nil
array_node :parent, 'parent', :default_value=>[], :class=>PomId
end

class JenkinsBuildInfoList < BuildInfoList
  include FlatHashList
  attr_reader :hash_list

  def initialize(options, thread_number = 5)
    @jenkins_servers = options[:jenkins_list]
    @jobs = options[:job_list]
    @type = options[:type]
    @hash_list = []
    
    @jobs.each do |jb|
      @hash_list << {jb => []}
    end
    super
  end

  def save_build_info
    @jobs.each do |jb|
      @jenkins_servers.each do |js|
        parallel_save_build_info_1_job(:type=>@type, :js=>js, :jb=>jb) {|options| get_build_info(options)}
      end
    end  
    self
  end  

  def last_build_number_for_job(options={})
    JenkinsBuildInfoList.last_build_number(options[:js], options[:jb])
  end

  def each_build_id(options, &block)
    JenkinsBuildInfoList.last_build_number(options[:js], options[:jb]).downto(0) {|bn| block.call options.merge(:bn=>bn)}
  end

  def create_thread_key(options={})
    options[:js] + options[:jb]
  end

  def save_1_build_info(options, info)
    jb = options[:jb]
    @mutex.synchronize { 
      @hash_list.find {|h| h.key? jb}[jb] << info
      @hash_list.find {|h| h.key? jb}[jb].sort! {|a, b| b[:url] <=> a[:url]}
    }
  end

  def get_build_info(options)
    log "#{__FILE__}, #{__LINE__}, options: #{options.inspect}"
    JenkinsBuildInfo.new(options).build_info
  end

  def self.last_build_number(js, jb)
    build_url = 'https://' + js + ':8080/job/' + jb
    file = jb
    ret = -1

    begin
      ret=RemoteUrl.get_url(build_url, file) do |file|
        JenkinsBuildInfoList.get_build_number file
      end
    rescue Exception => e  
      log "#{__FILE__}, #{__LINE__}, #{e.message}, #{e.backtrace.join("\n")}", 'debug'
    end
    log "#{__FILE__}, #{__LINE__}, last_build_number: #{ret}"
    ret
  end

  def self.get_build_number(file)
    content=Nokogiri::HTML(open(file))
    job = content.css('title').children.text.split[0]
    ret = content.css('a').select {|o| /\/job\/#{job}\/[0-9]+/ =~ o['href']}.map {|o| $1.to_i if /\/job\/#{job}\/([0-9]+)/ =~ o['href']}.uniq.sort[-1].to_i
  end
end

class BuildInfo
  def build_info
    if !@build_info or @build_info.empty?
      url = build_info_url
      log "#{__FILE__}, #{__LINE__}: url: " << url, 'debug'
      
      @build_info = get_build_url(url) {|f| 
        info = parse_build_info f
      }
      merge_other_build_info
    end
    log "#{__FILE__}, #{__LINE__}: @build_info: " << @build_info.inspect, 'debug'
    @build_info
  end

  def get_build_url(url, &block)
    file = file_from_url(url) 
    file.size > 0 ? RemoteUrl.get_url(url, file, &block) : false
  end
end

class SonarBuildInfo < BuildInfo
  include GitRepo

  def initialize(options = {})
    @gId = options[:gId]
    @aId = options[:aId]
  end

  def build_info_url
    @build_info_url ||= 'https://eseecisav71.emea.nsn-net.net:9000/api/measures/component_tree?asc=false&ps=100&metricSortFilter=withMeasuresOnly&p=1&s=metric%2Cname&metricSort=test_execution_time&baseComponentKey=' + @gId + '%3A' + @aId + '&metricKeys=test_execution_time&strategy=leaves'
  end

  def build_url
    @build_url ||= 'https://eseecisav71.emea.nsn-net.net:9000/component_measures/metric/test_execution_time/list?id=' + @gId + '%3A' + @aId
  end

  def file_from_url(url)
    if /https:\/\/(.*)=(.*)%3A(.*?)&.*/ =~ url
      file = 'sonar' + '.' + $2 + '.' + $3
    else
      log "#{__FILE__}, #{__LINE__}, invalid url: #{url}", 'WARN'
      ""
    end
  end

  def parse_build_info(file)
    hash_list = []
    content = IO.read file
    log "#{__FILE__}, #{__LINE__}: " << content, 'debug'
    data_hash_array = JSON.parse content
    data_hash_array['components'].each do |c|
      hash_list << {:file=>c['path'], :ut_duration=>DurationDecoder.msec_to_sec(c['measures'][0]['value']), :url=>build_url}
    end
    log "#{__FILE__}, #{__LINE__}: hash_list: " << hash_list.inspect, 'debug'
    hash_list
  end

  def merge_other_build_info
    @build_info.each {|h| h.merge!({:url=>build_url})}
  end
end

class SonarUTNoBuildInfo < BuildInfo
  include GitRepo

  def initialize(options = {})
    @gId = options[:gId]
    @aId = options[:aId]
    @file = options[:file]
    @sp = options[:sp]
    @git_repo_dir = GitRepo::Git_home_dir + '/' + @sp
  end

  def build_info_url
    log "#{__FILE__}, #{__LINE__}: @gId: " << @gId, 'debug'
    log "#{__FILE__}, #{__LINE__}: @file: " << @file, 'debug'
    @build_info_url ||= 'https://eseecisav71.emea.nsn-net.net:9000/api/measures/component?additionalFields=periods&componentKey=' + @gId + '%3A' + @aId + '%3A' + @file.gsub(/\//, '%2F') + '&metricKeys=new_technical_debt%2Cblocker_violations%2Cbugs%2Cburned_budget%2Cbusiness_value%2Cclasses%2Ccode_smells%2Ccomment_lines%2Ccomment_lines_density%2Ccomplexity%2Cclass_complexity%2Cfile_complexity%2Cfunction_complexity%2Cbranch_coverage%2Cnew_it_branch_coverage%2Cnew_branch_coverage%2Cconfirmed_issues%2Ccoverage%2Cnew_it_coverage%2Cnew_coverage%2Ccritical_violations%2Cpitest_mutations_detected%2Cdirectories%2Cduplicated_blocks%2Cduplicated_files%2Cduplicated_lines%2Cduplicated_lines_density%2Ceffort_to_reach_maintainability_rating_a%2Cfalse_positive_issues%2Cfiles%2Cfunctions%2Cgenerated_lines%2Cgenerated_ncloc%2Chigh_severity_vulns%2Cinfo_violations%2Cinherited_risk_score%2Cviolations%2Cit_branch_coverage%2Cit_coverage%2Cit_line_coverage%2Cit_uncovered_conditions%2Cit_uncovered_lines%2Cpitest_mutations_killed%2Cline_coverage%2Cnew_it_line_coverage%2Cnew_line_coverage%2Clines%2Cncloc%2Clines_to_cover%2Cnew_it_lines_to_cover%2Cnew_lines_to_cover%2Clow_severity_vulns%2Csqale_rating%2Cmajor_violations%2Cmedium_severity_vulns%2Cpitest_mutations_memoryError%2Cminor_violations%2Cpitest_mutations_coverage%2Cnew_blocker_violations%2Cnew_bugs%2Cnew_code_smells%2Cnew_critical_violations%2Cnew_info_violations%2Cnew_violations%2Cnew_major_violations%2Cnew_minor_violations%2Cnew_vulnerabilities%2Cpitest_mutations_noCoverage%2Copen_issues%2Coutage_risks_total%2Coutage_risks_blocker%2Coutage_risks_critical%2Coutage_risks_info%2Coutage_risks_major%2Coutage_risks_minor%2Coverall_branch_coverage%2Cnew_overall_branch_coverage%2Coverall_coverage%2Cnew_overall_coverage%2Coverall_line_coverage%2Cnew_overall_line_coverage%2Cnew_overall_lines_to_cover%2Coverall_uncovered_conditions%2Cnew_overall_uncovered_conditions%2Coverall_uncovered_lines%2Cnew_overall_uncovered_lines%2Cprojects%2Cpublic_api%2Cpublic_documented_api_density%2Cpublic_undocumented_api%2Calert_status%2Creleasability_rating%2Creliability_rating%2Creliability_remediation_effort%2Cnew_reliability_remediation_effort%2Creopened_issues%2Csecurity_rating%2Csecurity_remediation_effort%2Cnew_security_remediation_effort%2Cskipped_tests%2Cstatements%2Cpitest_mutations_survived%2Cteam_size%2Csqale_index%2Csqale_debt_ratio%2Cnew_sqale_debt_ratio%2Cpitest_mutations_timedOut%2Ctotal_dependencies%2Cpitest_mutations_total%2Creleasability_effort%2Ctotal_vulnerabilities%2Cuncovered_conditions%2Cnew_it_uncovered_conditions%2Cnew_uncovered_conditions%2Cuncovered_lines%2Cnew_it_uncovered_lines%2Cnew_uncovered_lines%2Ctest_execution_time%2Ctest_errors%2Ctest_failures%2Ctest_success_density%2Ctests%2Cpitest_mutations_unknown%2Cvulnerabilities%2Cvulnerable_component_ratio%2Cvulnerable_dependencies%2Cwont_fix_issues'
  end

  def file_from_url(url = '')
    log "#{__FILE__}, #{__LINE__}: @gId: " << @gId, 'debug'
    log "#{__FILE__}, #{__LINE__}: @file: " << @file, 'debug'
    file = 'sonar.ut.no' + '.' + @gId + '.' + @file.gsub(/\//, '.')
  end

  def parse_build_info(file)
    ut_no = 0
    content = IO.read file
    log "#{__FILE__}, #{__LINE__}: file: #{@file}, content: " << content, 'debug'
    data_hash_array = JSON.parse content
    ut_no = data_hash_array['component']['measures'].select {|m| m['metric'] == 'tests'}[0]['value'].to_i
    log "#{__FILE__}, #{__LINE__}: ut_no: " << ut_no.to_s << ", file: " << @file, 'debug'
    {:ut_no=>ut_no}
  end

  def merge_other_build_info
  end
end

class JenkinsBuildInfo < BuildInfo
  def initialize(options = {})
    @type = options[:type]
    @jenkins = options[:js]
    @job = options[:jb]
    @build_number = options[:bn]
  end

  def build_info_url
    @build_info_url ||= 'https://' + @jenkins + ':8080/job/' + @job + '/' + @build_number.to_s + '/timestamps/?time=HH:mm:ss&appendLog'
  end

  def build_time_url
    @build_time_url ||= 'https://' + @jenkins + ':8080/job/' + @job + '/' + @build_number.to_s + '/'
  end

  def merge_other_build_info
    @build_info.merge!({:type => @type})
    log "#{__FILE__}, #{__LINE__}, @build_info: #{@build_info}"
    @build_info.merge!({:url => build_time_url})
    if duration_date = get_build_time(build_time_url)
      log "#{__FILE__}, #{__LINE__}, date: #{duration_date}"
      @build_info.merge!(duration_date)
    else
      @build_info.merge!({:duration => '', :date=>Time.new(0, 0, 0, 0, 0, 0)})
    end  
    log "#{__FILE__}, #{__LINE__}, @build_info: #{@build_info.inspect}", 'debug'
  end

  def parse_build_time(file)
    page = Nokogiri::HTML(open(file))
    if node = page.css('a').select{|job| /(GATE|EXP|CHECK)-.*\/buildTimeTrend/ =~ job['href']}[0]
      time = node.text
    else
      time = ''
    end
    if page.css('h1').select{|head| /Build #[0-9]+\s.+\([A-Za-z]+\s+([A-Za-z]+)\s+([0-9]{2})\s+([0-9]{2}):([0-9]{2}):([0-9]{2})\s+[A-Z]+\s+([0-9]{4})/ =~ head.text}.size > 0
      date = Time.new($6, $1, $2, $3, $4, $5)
    else
      date = ''
    end
    {:duration => DurationDecoder.time_in_min(time), :date=>date}
  end

  def parse_labaction_time(file)
    install_duration, test_duration = '', ''

    content = Nokogiri::HTML(open(file))
    if prenode = content.css('td').select{|td| td.text == 'install'}[0]
      index = content.css('td').index prenode
      install_duration = content.css('td')[index+1].text.gsub(/\s*/, '')
    end
    if prenode = content.css('td').select{|td| td.text == 'Run tests'}[0]
      index = content.css('td').index prenode
      test_duration = content.css('td')[index+1].text.gsub(/\s*/, '')
    end
    [install_duration, test_duration]
  end

  def parse_ta_number(file)
    passed_ta, failed_ta = 0, 0
    content = Nokogiri::HTML(open(file))
    node = content.css('td').select {|n| /^Tests\([0-9]+\/[0-9]+\)$/ =~ n.text }
    if node.size > 0 && /Tests\(([0-9]+)\/([0-9]+)\)/ =~ node[0].text
      passed_ta = $1.to_i
      failed_ta = $2.to_i
    end
    passed_ta + failed_ta
  end

  def get_build_time(url)
    if /https:\/\/(.*):[0-9]+.*((GATE|EXP|CHECK)-.*)\/(.*)\// =~ url
      jenkins, job, build = $1, $2, $4
      file = 'consoleText' + '.' + jenkins + '.' + job + '.' + build + '.' + 'time'
      ret = false
      begin
        ret = RemoteUrl.get_url(url, file) do |file|
          parse_build_time file
        end
      rescue Exception => e
        log "#{__FILE__}, #{__LINE__}, #{e.message}, #{e.backtrace.join("\n")}"
      end  
      ret
    else
      log "#{__FILE__}, #{__LINE__}, invalid url: #{url}", 'WARN'
      false
    end
  end

  def parse_build_info(file)
    module_to_build, change, change_ids, result, end_time, res_id, upgrade_url, upgrade_duration, test_url, test_duration, zuul_project, ta_number = '', '', '', '', '', '', '', 0, '', 0, '', 0

    content = IO.read(file)
    content.gsub!(/\n/, '')

    module_to_build = $2.strip if /\[mpp\] Modules to build:([0-9]{2}:[0-9]{2}:[0-9]{2}\s*\[mpp\]\s*)*(.*?)[0-9]{2}:[0-9]{2}:[0-9]{2}/ =~ content
    change = $1 if /ZUUL_CHANGE=(.*?)[0-9]{2}:[0-9]{2}:[0-9]{2}/ =~ content
    change_ids = $1 if /ZUUL_CHANGE_IDS=(.*?)[0-9]{2}:[0-9]{2}:[0-9]{2}/ =~ content
    result = $1 if /Finished: (FAILURE|ABORTED|SUCCESS)/ =~ content
    end_time = parse_end_time(content, result)
    res_id = parse_res_id content
    result = "ONGOING" if result.size == 0
    zuul_project = $1 if /ZUUL_PROJECT=(.*?)[0-9]{2}:[0-9]{2}:[0-9]{2}/ =~ content
    
    upgrade_url = get_upgrade_url content
    ret = parse_upgrade_url upgrade_url
    upgrade_duration, test_duration = ret[0], ret[1]

    test_url = get_test_url content
    ret = parse_test_url test_url
    test_duration += ret[0]
    ta_number = ret[1]

    log "#{__FILE__}, #{__LINE__}, Thread: #{Thread.current}, change: #{change}, change_ids: #{change_ids}, result: #{result}, end_time: #{end_time}, res_id: #{res_id}, module_to_build: #{module_to_build}, file: #{file}"

    hash = {}
    hash.merge!({:module_to_build => module_to_build, :change => change, :change_ids => change_ids, :result => result, :end_time => end_time, :res_id => res_id, :upgrade_url => upgrade_url, :upgrade_duration => upgrade_duration, :test_url => test_url, :test_duration => test_duration, :zuul_project => zuul_project, :ta_number => ta_number })
  end

  def parse_res_id(content)
    /[0-9]{2}:[0-9]{2}:[0-9]{2}\s+res_id=(.*?)[0-9]{2}:[0-9]{2}:[0-9]{2}/ =~ content ? $1: ''
  end

  def parse_end_time(content, result)
    end_time = (result.size > 0 && /.*([0-9]{2}:[0-9]{2}:[0-9]{2}).*Finished: (FAILURE|ABORTED|SUCCESS)/ =~ content) ? $1 : ''
  end

  def get_upgrade_url(content)
    upgrade_url = ''

    upgrade_url = $1 if /\[mpp\] Post message=.*?: MPP upgrade .*? start:[0-9]{2}:[0-9]{2}:[0-9]{2}\s+\[mpp\]\s+-\s+(http:\/\/.*?)\s+to gerrit review/ =~ content
  end

  def parse_upgrade_url(url)
    upgrade_duration, test_duration = 0, 0

    if url
      ret = JenkinsBuildInfo.get_labaction_url_html(url) do |file|
        parse_labaction_time(file)
      end
      upgrade_duration = DurationDecoder.time_in_min(ret[0]) if ret
      test_duration = DurationDecoder.time_in_min(ret[1]) if ret
    end
    [upgrade_duration, test_duration]
  end

  def get_test_url(content)
    test_url = ''

    test_url = $1 if /\[mpp\] Post message=.*?: MPP test .*? start:[0-9]{2}:[0-9]{2}:[0-9]{2}\s+\[mpp\]\s+-\s+(http:\/\/[^\s]*)\s+to gerrit review/ =~ content
  end

  def parse_test_url(url)
    test_duration, ta_number = 0, 0

    if url
      ret = JenkinsBuildInfo.get_labaction_url_html(url) do |file|
        time = parse_labaction_time(file)
        number = parse_ta_number(file)
        [time, number].flatten
      end
      test_duration = DurationDecoder.time_in_min(ret[1]) if ret
      ta_number = ret[2] if ret
    end
    [test_duration, ta_number]
  end

  def self.get_labaction_url_html(url, &block)
    if /http:\/\/.*action_dir=([0-9_]*)&lab=(.*)&project.*/ =~ url
      date, lab = $1, $2
      file = 'labaction' + '.' + lab + '.' + date

      # just let exception pass to stop further checking deleted labactions
      RemoteUrl.get_url(url, file, &block)
    else
      log "#{__FILE__}, #{__LINE__}, invalid url: #{url}", 'WARN'
      false
    end
  end

  def file_from_url(url)
    if /https:\/\/(.*):[0-9]+.*((GATE|EXP|CHECK)-.*?)\/(\d+)\/(.+)/ =~ url
      file = 'consoleText' + '.' + $1 + '.' + $2 + '.' + $4
      log "#{__FILE__}, #{__LINE__}, file: #{file}", 'debug'
      file
    else
      log "#{__FILE__}, #{__LINE__}, invalid url: #{url}", 'WARN'
      ""
    end
  end

end

class DurationDecoder
  def self.time_in_min(time)
    hr, min = 0, 0
    if /([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})/ =~ time
      hr, min = $1.to_i, $2.to_i
    else
      hr = $1.to_i if /([0-9]+)\s+hr/ =~ time
      min = $1.to_i if /([0-9]+)\s+min/ =~ time
    end
    log("#{__FILE__}, #{__LINE__}, time: #{time}", 'debug')
    log("#{__FILE__}, #{__LINE__}, hr: #{hr}, min: #{min}", 'debug')
    60 * hr + min
  end

  def self.msec_to_sec(time)
    (time.to_f / 1000).round
  end
end

module ReadSaveFile
  def read(filename)
    list = []
    File.open(filename, 'r') do |file|
      file.read.each_line do |l|
        list << l.strip
      end
    end
    list
  end

  def save(filename, hash_list)
    log("#{__FILE__}, #{__LINE__}, hash_list: #{hash_list}", 'debug')
    system("rm -rf #{filename}")
    unless hash_list.size > 0
      File.open(filename, 'w+') {|file| file.write "\n" }
      return
    end
    File.open(filename, 'w+') do |file|
      hash_list[0].sort.each { |k, v|
        file.write "#{k},"
      }
      file.write "\n"
    end
    File.open(filename, 'a+') do |file|
      hash_list.each {|h| 
        h.sort.each { |k, v|
          file.write "#{v},"
        }
        file.write "\n"
      }
    end
  end
end

class RemoteUrl
  def self.get_url(url, file, &block)
    command = "wget -q --no-check-certificate '#{url}' -O #{file}"
    log "#{__FILE__}, #{__LINE__}, url: #{url}, file: #{file}", 'debug'

    system("rm -rf #{file}")
    begin
      raise "error downloading url: #{url}" unless system(command)
      ret = block.call file if block
    rescue Exception => e
      raise "line: #{__LINE__}, exception caught: #{e.message}. #{e.class}, #{e.backtrace.join("\n")}, block: #{block}"
    ensure  
      system("rm -rf #{file}")
    end
  end
end
