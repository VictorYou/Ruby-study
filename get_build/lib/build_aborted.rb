require 'log'
require 'build_info'

module BuildAborted
  attr_reader :data
  attr_reader :aborted_build

  def aborted_build
    unless @aborted_build
      @aborted_build = get_aborted_build(@hash_list_starting) if hash_list_starting
    end
    unless @aborted_build
      @aborted_build = get_aborted_build(@hash_list) if @hash_list
    end  
    @aborted_build
  end

  def get_aborted_build(hash_list)
    aborted_build_list = []
    hash_list.each do |h|
      h.values[0].select {|b| b[:result] == "ABORTED"}.each { |build|
        previous_change_ids = build[:change_ids].split[0..-2].join(' ')
        log "build change ids: #{build[:change_ids]}"
        log "previous_change_ids: #{previous_change_ids}"

        previous_builds = h.values[0].select {|b| b[:change_ids] == previous_change_ids} if previous_change_ids.size > 0

        if previous_builds
          previous_build = previous_builds.select {|b| b[:end_time] == build[:end_time]}
          if previous_build && previous_build.size > 0 && /(FAILURE|ABORTED)/ =~ previous_build[0][:result]
            aborted_build_list << {:url => build[:url], :module => build[:module_to_build], :duration => build[:duration], :previous_url => previous_build[0][:url], :previous_module => previous_build[0][:module_to_build]} if previous_build && previous_build.size > 0 && /(FAILURE|ABORTED)/ =~ previous_build[0][:result] && compare_module_to_build(build[:module_to_build], previous_build[0][:module_to_build])
          end
        end
      }
    end
    aborted_build_list
  end

  def compare_module_to_build(this, pre)
    if @@CONFIG_COMPARE_MODULES_TO_BUILD
      this != pre
    else
      true
    end  
  end

  def no_compare(this, pre)
  end

end

class AllBuildInfo
  include BuildAborted
end
