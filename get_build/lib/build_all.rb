require 'log'
require 'build_info'

module BuildAll
  attr_reader :build_starting
  attr_reader :all_build
  attr_reader :hash_list_starting
  attr_reader :date

  def all_build
    @all_build ||= []
    unless @all_build.size > 0 
      log "@hash_list: #{@hash_list}"
      @all_build = flat_list.map{|h| h.dup}.each {|h| h.keep_if {|k, v| k !=:change_ids } }
      log "@all_build: #{@all_build}"
      log "@all_build.size: #{@all_build.size}"
      @all_build
    end  
    @all_build
  end

  def build_starting(date='2018-01-01')
    @date = date
    year, month, day = 0, 0, 0
    year, month, day = $1, $2, $3 if /(\d+)-(\d+)-(\d+)/ =~ date

    unless @build_starting
      @build_starting = all_build.select {|b| b[:date] > Time.new(year, month, day, 0, 0, 0)}
    end
    @build_starting
  end

  def build_starting_for_analysis
    ret = []
    duplicated_build_starting = build_starting.collect {|h| h.dup}
    log "duplicated_build_starting: #{duplicated_build_starting.inspect}"
    success_hash_build = BuildAnalyser.valid_build(duplicated_build_starting)
    log "success_hash_build: #{success_hash_build.inspect}"

    ret.concat CheckBuildAnalyser.build_starting(success_hash_build)
    ret.concat GateUpgradeBuildAnalyser.build_starting(success_hash_build)
    ret.concat ExpUpgradeBuildAnalyser.build_starting(success_hash_build)
    ret.concat GateTestBuildAnalyser.build_starting(success_hash_build)
    ret.concat ExpTestBuildAnalyser.build_starting(success_hash_build)
    ret.uniq
  end

  def hash_list_starting
    year, month, day = 0, 0, 0
    year, month, day = $1, $2, $3 if /(\d+)-(\d+)-(\d+)/ =~ date

    unless @hash_list_starting
      @hash_list.extend(HashArrayDup)
      @hash_list_starting = @hash_list.dup_hash_list.each do |h|
        h.merge!(h.keys[0] => h.values[0].select {|b| b[:date] > Time.new(year, month, day, 0, 0, 0)})
      end
    end
    @hash_list_starting
  end
end

class BuildAnalyser
  def self.valid_build(hash_build)
    hash_build.keep_if {|h| h[:result] == "SUCCESS" && h[:module_to_build].size > 0}
  end

  def self.build_starting(hash_build)
    ret = []
    duration_key = self.key
    hash_build_by_type = filtered_hash_build(hash_build)
    modules_list = hash_build_by_type.collect {|h| h[:module_to_build]}.uniq.sort
    modules_list.each {|m| 
      modules_hash = hash_build_by_type.select {|h| h[:module_to_build] == m}
      ret << modules_hash.sort_by {|h| h[duration_key]}[0]
    }
    ret
  end
end

class CheckBuildAnalyser < BuildAnalyser
  def self.filtered_hash_build(hash_build)
    hash_build.dup.keep_if {|h| h[:type] == 'CHECK'}
  end

  def self.key
    :duration
  end
end

class GateBuildAnalyser < BuildAnalyser
  def self.filtered_hash_build(hash_build)
    duration_key = key
    hash_build.dup.keep_if {|h| h[:type] == 'GATE' && h[duration_key] > 0}
  end
end

class GateUpgradeBuildAnalyser < GateBuildAnalyser
  def self.key
    :upgrade_duration
  end
end

class GateTestBuildAnalyser < GateBuildAnalyser
  def self.key
    :test_duration
  end
end

class ExpBuildAnalyser < BuildAnalyser
  def self.filtered_hash_build(hash_build)
    duration_key = key
    hash_build.dup.keep_if {|h| h[:type] == 'EXP' && h[duration_key] > 0}
  end
end

class ExpUpgradeBuildAnalyser < ExpBuildAnalyser
  def self.key
    :upgrade_duration
  end
end

class ExpTestBuildAnalyser < ExpBuildAnalyser
  def self.key
    :test_duration
  end
end

module HashArrayDup
  def dup_hash_list
    self.map {|h| h.dup}
  end
end

class AllBuildInfo
  include BuildAll
end  
