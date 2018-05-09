require 'log'
require 'build_info'

class BuildResId < AllBuildInfo
  attr_reader :data

  def save_res_id
    get_build_info
    @data = get_res_id (@hash_list)
  end

  def get_res_id(hash_list)
    build_list = []

    hash_list.each {|h| build_list.concat h.values}
    build_list.flatten.each {|h| h.keep_if {|k, v| k==:url || k== :res_id} }
  end
end
