require 'nokogiri'
require 'log'

system("rm -rf index.html")
unless system("wget --no-check-certificate https://eslinb86.emea.nsn-net.net:8080/view/Gate/")
  log "fail to download page"
end

page = Nokogiri::HTML(open("index.html"))

log "save gate jobs to file: gate_jobs"

File.open('gate_jobs', 'w+') do |file|
  page.css('a').select {|gj| /job\/GATE-.*-component-build-deploy-test/ =~ gj['href'] }.map {|job| job.text if /GATE-.*-component-build-deploy-test/ =~ job.text }.select {|v| v}.sort.uniq.each { |job| file.write "#{job}\n" }

end  

