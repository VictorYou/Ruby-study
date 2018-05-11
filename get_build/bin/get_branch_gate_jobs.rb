require 'nokogiri'
require 'log'

system("rm -rf index.html")
unless system("wget --no-check-certificate https://euca-10-131-38-213.eucalyptus.es-ka-eu-dhn-09.eecloud.nsn-net.net:8080/view/Branch_Gate/")
  log "fail to download page"
end

page = Nokogiri::HTML(open("index.html"))

log "save gate jobs to file: branch_gate_jobs"

File.open('branch_gate_jobs', 'w+') do |file|
  page.css('a').select {|gj| /job\/BRANCH-GATE-.*-component-build-deploy-test/ =~ gj['href'] }.map {|job| job.text if /BRANCH-GATE-.*-component-build-deploy-test/ =~ job.text }.select {|v| v}.sort.uniq.each { |job| file.write "#{job}\n" }

end  

