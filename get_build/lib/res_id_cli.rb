require 'build_cli'
require 'build_res_id'

class ResIdCLI < BuildCLI
  def get_data  
    build_res = BuildResId.new(@jenkins_server_list, @gate_job_list)
    build_res.save_res_id
    build_res.data
  end  

  def save_file hash_list
    # save the builds to a file
    log "hash_list: #{hash_list}"
    log "save the builds to a file: builds_res_id"

    save('builds_res_id', hash_list)
  end
end
