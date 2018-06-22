require '../lib/build_info'
require 'mocha/test_unit'

describe "test BuildInfo class to get build hash" do
  it "should fetch web page from url and save it to a local file" do
    RemoteUrl.expects(:system).with('rm -rf consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047').returns(true)
    RemoteUrl.expects(:system).with('rm -rf consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047').returns(true)
    RemoteUrl.expects(:system).with("wget -q --no-check-certificate 'https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047/timestamps/?time=HH:mm:ss&appendLog' -O consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047").returns(true)
    RemoteUrl.expects(:log).returns(true)
    RemoteUrl.expects(:log).returns(true)
    expect(RemoteUrl.get_url('https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047/timestamps/?time=HH:mm:ss&appendLog', 'consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047') {|f| f}).to eq 'consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047'
  end

  # this saves time to further check labactions that are deleted
  it "should raise exception when cannot get lab url" do
    url = 'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20180119_194851_493057&lab=CloneCLAB2774&project=nass'
    file = 'labaction.CloneCLAB2774.20180119_194851_493057'
    RemoteUrl.expects(:get_url).raises(Exception, "error accessing lab action page")
    expect {JenkinsBuildInfo.get_labaction_url_html('http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20180119_194851_493057&lab=CloneCLAB2774&project=nass') {|f| f}}.to raise_error(Exception, "error accessing lab action page")
  end

  it "should form correct file name from url for sonar bulds" do
    @tester = SonarBuildInfo.new({})
    expect(@tester.file_from_url('https://eseecisav71.emea.nsn-net.net:9000/api/measures/component_tree?asc=false&ps=100&metricSortFilter=withMeasuresOnly&p=1&s=metric%2Cname&metricSort=test_execution_time&baseComponentKey=com.nokia.oss.isdk.mediation.ftppm%3Aisdk-ftp-pm&metricKeys=test_execution_time&strategy=leaves')).to eq 'sonar.com.nokia.oss.isdk.mediation.ftppm.isdk-ftp-pm'
  end

  it "should form correct file name from url and call get_url" do
    @tester = JenkinsBuildInfo.new({})
    @tester.expects(:log).returns true
    expect(@tester.file_from_url('https://eslinb87.emea.nsn-net.net:8080/view/Gate/job/GATE-adap_core1-component-build-deploy-test/93//timestamps/?time=HH:mm:ss&appendLog')).to eq 'consoleText.eslinb87.emea.nsn-net.net.GATE-adap_core1-component-build-deploy-test.93'
  end

  it "should return false when invalid url is given" do
    @tester = JenkinsBuildInfo.new({})
    @tester.expects(:log).returns true
    expect(@tester.file_from_url('https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/')).to eq ""
  end

  it "should return time in minutes giving time" do
    expect(DurationDecoder.time_in_min('1 min 5 sec')).to eq 1
    expect(DurationDecoder.time_in_min('2 hr 39 min')).to eq 159
    expect(DurationDecoder.time_in_min('57 sec')).to eq 0
    expect(DurationDecoder.time_in_min('1:32:02')).to eq 92
  end

  it "should return seconds giving milli seconds" do
    expect(DurationDecoder.msec_to_sec(12345)).to eq 12
    expect(DurationDecoder.msec_to_sec(12545)).to eq 13
  end

  it "should read content file and return info" do
    file = 'consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047'
    @tester = JenkinsBuildInfo.new({})
    content = IO.read(file)
    content.gsub!(/\n/, '')
    upgrade_url = 'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_083843_180224&lab=CloneCLAB2890&project=nass'
    test_url = 'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_100718_206973&lab=CloneCLAB2890&project=nass'
    result = $1 if /Finished: (FAILURE|ABORTED|SUCCESS)/ =~ content

    @tester.expects(:log).returns(true)
    @tester.expects(:get_upgrade_url).with(content).returns upgrade_url
    @tester.expects(:parse_upgrade_url).with(upgrade_url).returns [40, 20]
    @tester.expects(:get_test_url).with(content).returns test_url
    @tester.expects(:parse_test_url).with(test_url).returns [10, 20]
    @tester.expects(:parse_end_time).with(content, result).returns '10:29:39'
    @tester.expects(:parse_res_id).with(content).returns 'nass/smu_platform1_git/18.0.0.96'
    expect(@tester.parse_build_info(file)).to eq ({:module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :upgrade_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_083843_180224&lab=CloneCLAB2890&project=nass', :upgrade_duration=>40, :test_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_100718_206973&lab=CloneCLAB2890&project=nass', :test_duration=>30, :zuul_project=>'netact/nass', :ta_number => 20})
    
  end

  it "parse res_id giving content" do
    @tester = JenkinsBuildInfo.new({})

    content = IO.read('consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047')
    content.gsub!(/\n/, '')
    expect(@tester.parse_res_id(content)).to eq 'nass/smu_platform1_git/18.0.0.96'

    content = IO.read('consoleText.eslinb87.emea.nsn-net.net.GATE-radio3lte_static-component-build-deploy-test.17')
    content.gsub!(/\n/, '')
    expect(@tester.parse_res_id(content)).to eq '=res_id==radio3_lte_com.nsn.netact.man-8_17.8_17'
  end

  it "should read url and return test duration" do
    @tester = JenkinsBuildInfo.new({})
    url = 'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_100718_206973&lab=CloneCLAB2890&project=nass'

    JenkinsBuildInfo.expects(:get_labaction_url_html).with(url).returns(['', '00:40:15', 55])
    DurationDecoder.expects(:time_in_min).with('00:40:15').returns(40)
    expect(@tester.parse_test_url(url)).to eq [40, 55]
  end

  it "should read content file and return upgrade url" do
    @tester = JenkinsBuildInfo.new({})

    # test for gate pipeline
    content = IO.read('consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047')
    content.gsub!(/\n/, '')
    expect(@tester.get_upgrade_url(content)).to eq 'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_083843_180224&lab=CloneCLAB2890&project=nass'

    # test for exp pipeline
    content = IO.read('consoleText.eslinb87.emea.nsn-net.net.EXP-component-experimental-test.1492')
    content.gsub!(/\n/, '')
    expect(@tester.get_upgrade_url(content)).to eq 'http://brigida.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20180112_042240_311621&lab=CloneCLAB2275&project=N8_labs'
  end

  it "should read content file and return test url" do
    @tester = JenkinsBuildInfo.new({})

    # test for gate pipeline
    content = IO.read('consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047')
    content.gsub!(/\n/, '')
    expect(@tester.get_test_url(content)).to eq 'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_100718_206973&lab=CloneCLAB2890&project=nass'

    # test for exp pipeline
    content = IO.read('consoleText.eslinb87.emea.nsn-net.net.EXP-component-experimental-test.1492')
    content.gsub!(/\n/, '')
    expect(@tester.get_test_url(content)).to eq 'http://brigida.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20180112_050729_547028&lab=CloneCLAB2275&project=N8_labs'

  end

  it "should read upgrade url and return upgrade duration for gate pipeline" do
    @tester = JenkinsBuildInfo.new({})
    @tester.expects(:log).returns(true)
    url = 'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_083843_180224&lab=CloneCLAB2890&project=nass'

    BuildInfo.expects(:get_labaction_url_html).with(url).returns(['00:30:15', '00:40:15'])
    DurationDecoder.expects(:time_in_min).with('00:30:15').returns(30)
    DurationDecoder.expects(:time_in_min).with('00:40:15').returns(40)
    expect(@tester.parse_upgrade_url(url)).to eq [30, 40]
  end

  it "should read correct end time when it is in a different line than result" do
    file = 'consoletext.eslinb86.emea.nsn-net.net.GATE-NBI_INVENTORY-build-deploy-test.6'
    @tester = JenkinsBuildInfo.new({})
    content = IO.read(file)
    content.gsub!(/\n/, '')
    result = $1 if /Finished: (FAILURE|ABORTED|SUCCESS)/ =~ content
    expect(@tester.parse_end_time(content, result)).to eq '08:26:33'
  end

  it "should read correct end time when it is in the same line as result" do
    file = 'consoleText.eslinb87.emea.nsn-net.net.EXP-component-experimental-test.1492'
    @tester = JenkinsBuildInfo.new({})
    content = IO.read(file)
    content.gsub!(/\n/, '')
    result = $1 if /Finished: (FAILURE|ABORTED|SUCCESS)/ =~ content
    expect(@tester.parse_end_time(content, result)).to eq '05:17:26'
  end

  it "should return build info by giving jenkins and gate" do
    @tester = JenkinsBuildInfo.new({})
    build_info = {:change => '184333', :change_ids => '184333,1'}
    @tester.expects(:build_info_url).returns 'https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047'
    @tester.expects(:get_build_url).returns(build_info)
    @tester.expects(:merge_other_build_info).returns true
    expect(@tester.build_info).to eq build_info
  end

  it "should return build url by giving server, job and build number" do
    @tester = JenkinsBuildInfo.new(:type=>'GATE', :js=>'eslinb86.emea.nsn-net.net', :jb=>'GATE-nass-component-build-deploy-test', :bn=>1047)
    expect(@tester.build_info_url).to eq 'https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047/timestamps/?time=HH:mm:ss&appendLog'
  end

  it "should merge type, build url etc for jenkins build" do
    @tester = JenkinsBuildInfo.new(:type =>'GATE')
    build_time_url = 'https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047'
    @tester.expects(:build_time_url).returns build_time_url
    @tester.expects(:build_time_url).returns build_time_url
    @tester.instance_eval {@build_info = {}}
    @tester.expects(:get_build_time).returns({:duration=>'1 hr 55 min', :date=>Time.new(2017,'Jul',20,05,34,26)})
    @tester.merge_other_build_info
    expect(@tester.instance_eval {@build_info}).to eq ({:type =>'GATE', :url =>build_time_url, :duration => '1 hr 55 min', :date=>Time.new(2017,'Jul',20,05,34,26)})
  end

  it "should initialize build hash list correctly" do
    @tester = AllBuildInfo.new(['eslinb86.emea.nsn-net.net'], ['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test'])
    expect(@tester.instance_eval{@all_jobs}).to eq ['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test']
    expect(@tester.instance_eval{@zuul_project_list}).to eq ['med_core3']
    expect(@tester.instance_eval{@gate_jobs}).to eq ['GATE-med_core3-component-build-deploy-test']
    expect(@tester.instance_eval{@all_jobs}).to eq ['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test']
    expect(@tester.hash_list).to eq [{'GATE-med_core3-component-build-deploy-test'=>[]}, {'EXP-component-experimental-test'=>[]}, {'CHECK-component-build-unit-test'=>[]}]
    expect(@tester.instance_eval{@check_jobs}).to eq ['CHECK-component-build-unit-test']
    expect(@tester.instance_eval{@exp_jobs}).to eq ['EXP-component-experimental-test']
  end

  it "should initialize build hash list correctly" do
    @tester = JenkinsBuildInfoList.new(:jenkins_list=>['eslinb86.emea.nsn-net.net'], :job_list=>['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test'], :type=>'GATE')
    expect(@tester.instance_eval{@jobs}).to eq ['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test']
    expect(@tester.instance_eval{@jobs}).to eq ['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test']
    expect(@tester.instance_eval{@type}).to eq 'GATE'
    expect(@tester.hash_list).to eq [{'GATE-med_core3-component-build-deploy-test'=>[]}, {'EXP-component-experimental-test'=>[]}, {'CHECK-component-build-unit-test'=>[]}]
  end

  it "should initialize sonar build hash list correctly" do
    @tester = SonarBuildInfoList.new(:project_list=>['radio2_scli', 'radio3'])
    expect(@tester.hash_list).to eq [{'radio2_scli'=>[]}, {'radio3'=>[]}]
    expect(@tester.poms).to eq []
  end

  it "should read build number from a file name" do
    expect(JenkinsBuildInfoList.get_build_number('GATE-release-upgrade-NA17-2-verification')).to eq 1727
  end

  it "should return last build number by giving jenkins and gate" do
    RemoteUrl.expects(:get_url).returns 1047
    expect(JenkinsBuildInfoList.last_build_number('eslinb86.emea.nsn-net.net', 'GATE-release-upgrade-NA17-2-verification')).to eq 1047
  end

  it "should save 1 build info" do
    @tester = JenkinsBuildInfoList.new(:jenkins_list=>['eslinb86.emea.nsn-net.net'], :job_list=>['GATE-nass-component-build-deploy-test'], :type=>2)
    build_info = {:result => 'SUCCESS'}
    
    @tester.save_1_build_info({:type=>'GATE', :js=>'eslinb86.emea.nsn-net.net', :jb=>'GATE-nass-component-build-deploy-test', :bn=>1047}, build_info)
    expect(@tester.hash_list).to eq [{'GATE-nass-component-build-deploy-test'=>[build_info]}]
  end

  it "should save 1 build info for sonar build" do
    @tester = SonarBuildInfoList.new(:project_list=>['radio1'])
    build_info = [{:result => 'SUCCESS'}]
    
    @tester.save_1_build_info({:sp=>'radio1'}, build_info)
    expect(@tester.hash_list).to eq [{'radio1'=>build_info}]
  end

  it "should set common variable to be false if there is exception when saving 1 build info" do
    @tester = BuildInfoList.new({}, 2)
    build_info = {:result => 'SUCCESS'}
    
    @tester.expects(:save_1_build_info).returns true
    @tester.expects(:create_thread_key).returns('eslinb86.emea.nsn-net.netGATE-nass-component-build-deploy-test')
    @tester.save_build_info_1_build(:type=>'GATE', :js=>'eslinb86.emea.nsn-net.net', :jb=>'GATE-nass-component-build-deploy-test', :bn=>1047){|options| raise "an exception processing build info"}
    expect(@tester.instance_eval{@create_thread['eslinb86.emea.nsn-net.netGATE-nass-component-build-deploy-test']}).to eq false
  end

  it "should get build duration giving url" do
    @tester = JenkinsBuildInfo.new({})
    RemoteUrl.expects(:get_url).with('https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047/', 'consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047.time').returns ({:duration=>115, :date=>Time.new(2017,'Jul',20,05,34,26)})
    expect(@tester.get_build_time('https://eslinb86.emea.nsn-net.net:8080/job/GATE-nass-component-build-deploy-test/1047/')).to eq ({:duration=>115, :date=>Time.new(2017,'Jul',20,05,34,26)})
  end

  it "should parse build duration giving file" do
    @tester = JenkinsBuildInfo.new({})
    DurationDecoder.expects(:time_in_min).with('1 hr 55 min').returns(115)
    expect(@tester.parse_build_time('consoleText.eslinb86.emea.nsn-net.net.GATE-nass-component-build-deploy-test.1047.time')).to eq ({:duration=>115, :date=>Time.new(2017,'Jul',20,05,34,26)})
  end

  it "should parse lab action duration giving file" do
    @tester = JenkinsBuildInfo.new({})
    expect(@tester.parse_labaction_time('labaction.CloneCLAB2778.20180123_080809_498641')).to eq ['01:05:17', '00:43:24']
  end

  it "should filter out the builds from other projects" do
    build_info_list = [{'CHECK-component-unit-test' => [{:module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :upgrade_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_083843_180224&lab=CloneCLAB2890&project=nass', :upgrade_duration=>40, :test_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_100718_206973&lab=CloneCLAB2890&project=nass', :test_duration=>15, :zuul_project=>'netact/nass'}, {:module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :upgrade_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_083843_180224&lab=CloneCLAB2890&project=nass', :upgrade_duration=>40, :test_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_100718_206973&lab=CloneCLAB2890&project=nass', :test_duration=>15, :zuul_project=>'netact/nbi'}]}]
    zuul_project_list = ['nass']
    result_build_info_list = [{'CHECK-component-unit-test' => [{:module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :upgrade_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_083843_180224&lab=CloneCLAB2890&project=nass', :upgrade_duration=>40, :test_url=>'http://dome.netact.nsn-rdnet.net/mpp/dynamic/logs/lab_action?action_dir=20170720_100718_206973&lab=CloneCLAB2890&project=nass', :test_duration=>15, :zuul_project=>'netact/nass'}]}]
    AllBuildInfo.filter_hash_list(build_info_list, zuul_project_list)
    expect(build_info_list).to eq result_build_info_list
  end

  it "should parse ta number giving file" do
    @tester = JenkinsBuildInfo.new({})
    expect(@tester.parse_ta_number('labaction.clab798_small.20180116_072906_503763')).to eq 7
    expect(@tester.parse_ta_number('labaction.CloneCLAB2627.20180122_081643_824922')).to eq 0
  end

  it "should return create thread key as jenksins server + jenkins job" do
    @tester = JenkinsBuildInfoList.new(:jenkins_list=>['eslinb86.emea.nsn-net.net'], :job_list=>['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test'], :type=>'GATE')
    expect(@tester.create_thread_key({:js=>'eslinb86.emea.nsn-net.net', :jb=>'GATE-med_core3-component-build-deploy-test'})).to eq 'eslinb86.emea.nsn-net.netGATE-med_core3-component-build-deploy-test'
  end

  it "should pull repo if it exists locally" do
    self.extend GitRepo
    expects(:repo_in_local?).returns true
    expect(get_repo_cmd('isdk_ftp_pm')).to eq 'cd /home/viyou/repo/isdk_ftp_pm; git pull'
  end

  it "should clone repo if it does not exist locally" do
    self.extend GitRepo
    expects(:repo_in_local?).returns false
    expect(get_repo_cmd('isdk_ftp_pm')).to eq 'git clone ssh://viyou@gerrite1.ext.net.nokia.com:8282/netact/isdk_ftp_pm /home/viyou/repo/isdk_ftp_pm'
  end

  it "should save the pom file into poms" do
    extend PomList
    file = '/a/implementation/pom.xml'
    expects(:directory?).with(file).returns false
    expect(get_pom(file)).to eq [file]
  end

  it "should not save the pom file not under implementation" do
    extend PomList
    expects(:directory?).with('/a/pom.xml').returns false
    expect(get_pom('/a/pom.xml')).to eq []
  end

  it "should not save the pom file into poms" do
    extend PomList
    dir = '/a/implementation/b/implementation/pom.xml'
    expects(:directory?).with(dir).returns false
    expect(get_pom(dir, ['/a/implementation/pom.xml'])).to eq ['/a/implementation/pom.xml']
  end

  it "should get group id and artificat id from a pom file" do
    @tester = SonarBuildInfoList.new({:project_list=>[]})
    expect(@tester.get_id_from_pom('pom.xml')).to eq ({:gId=>'com.nokia.oss.isdk.mediation.ftppm', :aId=>'isdk-ftp-pm'})
  end

  it "should get grouop id with newline removed" do
    @tester = SonarBuildInfoList.new({:project_list=>[]})
    expect(@tester.get_id_from_pom('pom_newline.xml')).to eq ({:gId=>'com.nsn.eventpipe.se.eventcorrelator', :aId=>'gep-event-correlation-se'})
  end

  it "should get group id from parent if it does not have" do
    @tester = SonarBuildInfoList.new({:project_list=>[]})
    expect(@tester.get_id_from_pom('pom_gId_parent.xml')).to eq ({:gId=>'com.nsn.oss.nbi3gcpm.ftirp', :aId=>'pm-report-handler-su'})
  end

  it "should get correct build url for sonar build" do
    @tester = SonarBuildInfo.new({:gId=>'com.nokia.oss.isdk.mediation.ftppm', :aId=>'isdk-ftp-pm'})
    expect(@tester.build_url).to eq 'https://eseecisav71.emea.nsn-net.net:9000/component_measures/metric/test_execution_time/list?id=com.nokia.oss.isdk.mediation.ftppm%3Aisdk-ftp-pm'
  end

  it "should get correct build info url for sonar build" do
    @tester = SonarBuildInfo.new({:gId=>'com.nokia.oss.isdk.mediation.ftppm', :aId=>'isdk-ftp-pm'})
    expect(@tester.build_info_url).to eq 'https://eseecisav71.emea.nsn-net.net:9000/api/measures/component_tree?asc=false&ps=100&metricSortFilter=withMeasuresOnly&p=1&s=metric%2Cname&metricSort=test_execution_time&baseComponentKey=com.nokia.oss.isdk.mediation.ftppm%3Aisdk-ftp-pm&metricKeys=test_execution_time&strategy=leaves'
  end

  it "should parse ut file and time from file" do
    @tester = SonarBuildInfo.new({:gId=>'com.nokia.oss.isdk.mediation.ftppm', :aId=>'isdk-ftp-pm'})
    DurationDecoder.expects(:msec_to_sec).with('155892').returns 156
    DurationDecoder.expects(:msec_to_sec).with('102779').returns 103
    expect(@tester.parse_build_info('sonar.com.nokia.oss.isdk.mediation.ftppm.isdk-ftp-pm')).to eq [{:file=>'src/test/java/com/nsn/oss/mdk/collectors/ftp/FTPHelperImplTest.java', :ut_duration=>156, :url=>'https://eseecisav71.emea.nsn-net.net:9000/component_measures/metric/test_execution_time/list?id=com.nokia.oss.isdk.mediation.ftppm%3Aisdk-ftp-pm'}, {:file=>'src/test/java/com/nsn/oss/mdk/pm/converter/OMeSConverter3GPPV6_2_DTDTest.java', :ut_duration=>103, :url=>'https://eseecisav71.emea.nsn-net.net:9000/component_measures/metric/test_execution_time/list?id=com.nokia.oss.isdk.mediation.ftppm%3Aisdk-ftp-pm'}]
  end

  it "should flatten hash list" do
    @tester = SonarBuildInfoList.new({:project_list=>[]})
    @tester.instance_eval{@hash_list = [{:jb1=>[{:file=>'file1'}, {:file=>'file2'}]}, {:jb2=>[{:file=>'file3'}, {:file=>'file4'}]}]}
    expect(@tester.flat_list).to eq [{:key=>:jb1, :file=>'file1'}, {:key=>:jb1, :file=>'file2'}, {:key=>:jb2, :file=>'file3'}, {:key=>:jb2, :file=>'file4'}]
  end

  it "should merge build_url into sonar build info" do
    @tester = SonarBuildInfo.new({:gId=>'com.nokia.oss.isdk.mediation.ftppm', :aId=>'isdk-ftp-pm'})
    @tester.instance_eval {@build_info = [{:file=>'file1'}, {:file=>'file2'}]}
    @tester.expects(:build_url).returns 'https://sonar.com'
    @tester.expects(:build_url).returns 'https://sonar.com'
    @tester.merge_other_build_info
    expect(@tester.instance_eval{@build_info}).to eq [{:file=>'file1', :url=>'https://sonar.com'}, {:file=>'file2', :url=>'https://sonar.com'}]
  end

  it "should execute block against build number for jenkisn buid" do
    @tester = JenkinsBuildInfoList.new(:jenkins_list=>['eslinb86.emea.nsn-net.net'], :job_list=>['GATE-med_core3-component-build-deploy-test', 'EXP-component-experimental-test', 'CHECK-component-build-unit-test'], :type=>'GATE')
    arr = []
    JenkinsBuildInfoList.expects(:last_build_number).returns 3
    @tester.each_build_id({}) {|id| arr << id}
    expect(arr).to eq [{:bn=>3}, {:bn=>2}, {:bn=>1}, {:bn=>0}]
  end

  it "should execute block against gId/aId for sonar buid" do
    @tester = SonarBuildInfoList.new(:project_list=>['radio2_scli', 'radio3'])
    arr = []
    @tester.expects(:ids).returns [{:id=>'a'}, {:id=>'b'}]
    @tester.each_build_id({}) {|id| arr << id}
    expect(arr).to eq [{:id=>'a'}, {:id=>'b'}]
  end

  it "should return correct testfile url" do
    @tester = SonarUTNoBuildInfo.new({:gId=>'com.nokia.oss.isdk.mediation.ftppm.implementation', :aId=>'mdk-impl-ftp', :sp=>'isdk_ftp_pm', :file=>'src/test/java/com/nsn/oss/mdk/collectors/ftp/FTPHelperImplTest.java'})
    @tester.expects(:test_file_parent_level).returns 'mdk-impl-ftp'
    expect(@tester.build_info_url).to eq 'https://eseecisav71.emea.nsn-net.net:9000/api/measures/component?additionalFields=periods&componentKey=com.nokia.oss.isdk.mediation.ftppm.implementation%3Amdk-impl-ftp%3Asrc%2Ftest%2Fjava%2Fcom%2Fnsn%2Foss%2Fmdk%2Fcollectors%2Fftp%2FFTPHelperImplTest.java&metricKeys=new_technical_debt%2Cblocker_violations%2Cbugs%2Cburned_budget%2Cbusiness_value%2Cclasses%2Ccode_smells%2Ccomment_lines%2Ccomment_lines_density%2Ccomplexity%2Cclass_complexity%2Cfile_complexity%2Cfunction_complexity%2Cbranch_coverage%2Cnew_it_branch_coverage%2Cnew_branch_coverage%2Cconfirmed_issues%2Ccoverage%2Cnew_it_coverage%2Cnew_coverage%2Ccritical_violations%2Cpitest_mutations_detected%2Cdirectories%2Cduplicated_blocks%2Cduplicated_files%2Cduplicated_lines%2Cduplicated_lines_density%2Ceffort_to_reach_maintainability_rating_a%2Cfalse_positive_issues%2Cfiles%2Cfunctions%2Cgenerated_lines%2Cgenerated_ncloc%2Chigh_severity_vulns%2Cinfo_violations%2Cinherited_risk_score%2Cviolations%2Cit_branch_coverage%2Cit_coverage%2Cit_line_coverage%2Cit_uncovered_conditions%2Cit_uncovered_lines%2Cpitest_mutations_killed%2Cline_coverage%2Cnew_it_line_coverage%2Cnew_line_coverage%2Clines%2Cncloc%2Clines_to_cover%2Cnew_it_lines_to_cover%2Cnew_lines_to_cover%2Clow_severity_vulns%2Csqale_rating%2Cmajor_violations%2Cmedium_severity_vulns%2Cpitest_mutations_memoryError%2Cminor_violations%2Cpitest_mutations_coverage%2Cnew_blocker_violations%2Cnew_bugs%2Cnew_code_smells%2Cnew_critical_violations%2Cnew_info_violations%2Cnew_violations%2Cnew_major_violations%2Cnew_minor_violations%2Cnew_vulnerabilities%2Cpitest_mutations_noCoverage%2Copen_issues%2Coutage_risks_total%2Coutage_risks_blocker%2Coutage_risks_critical%2Coutage_risks_info%2Coutage_risks_major%2Coutage_risks_minor%2Coverall_branch_coverage%2Cnew_overall_branch_coverage%2Coverall_coverage%2Cnew_overall_coverage%2Coverall_line_coverage%2Cnew_overall_line_coverage%2Cnew_overall_lines_to_cover%2Coverall_uncovered_conditions%2Cnew_overall_uncovered_conditions%2Coverall_uncovered_lines%2Cnew_overall_uncovered_lines%2Cprojects%2Cpublic_api%2Cpublic_documented_api_density%2Cpublic_undocumented_api%2Calert_status%2Creleasability_rating%2Creliability_rating%2Creliability_remediation_effort%2Cnew_reliability_remediation_effort%2Creopened_issues%2Csecurity_rating%2Csecurity_remediation_effort%2Cnew_security_remediation_effort%2Cskipped_tests%2Cstatements%2Cpitest_mutations_survived%2Cteam_size%2Csqale_index%2Csqale_debt_ratio%2Cnew_sqale_debt_ratio%2Cpitest_mutations_timedOut%2Ctotal_dependencies%2Cpitest_mutations_total%2Creleasability_effort%2Ctotal_vulnerabilities%2Cuncovered_conditions%2Cnew_it_uncovered_conditions%2Cnew_uncovered_conditions%2Cuncovered_lines%2Cnew_it_uncovered_lines%2Cnew_uncovered_lines%2Ctest_execution_time%2Ctest_errors%2Ctest_failures%2Ctest_success_density%2Ctests%2Cpitest_mutations_unknown%2Cvulnerabilities%2Cvulnerable_component_ratio%2Cvulnerable_dependencies%2Cwont_fix_issues'
  end

  it "should form correct file name from url for sonar ut number builds" do
    @tester = SonarUTNoBuildInfo.new({:gId=>'com.nokia.oss.isdk.mediation.ftppm', :aId=>'mdk-impl-ftp', :sp=>'isdk_ftp_pm', :file=>'src/test/java/com/nsn/oss/mdk/collectors/ftp/FTPHelperImplTest.java'})
    expect(@tester.file_from_url).to eq 'sonar.ut.no.com.nokia.oss.isdk.mediation.ftppm.src.test.java.com.nsn.oss.mdk.collectors.ftp.FTPHelperImplTest.java'
  end

  it "should parse ut no from file" do
    @tester = SonarUTNoBuildInfo.new({:gId=>'com.nokia.oss.isdk.mediation.ftppm', :aId=>'mdk-impl-ftp', :sp=>'isdk_ftp_pm', :file=>'src/test/java/com/nsn/oss/mdk/collectors/ftp/FTPHelperImplTest.java'})
    expect(@tester.parse_build_info('sonar.ut.no.com.nokia.oss.isdk.mediation.ftppm.src.test.java.com.nsn.oss.mdk.collectors.ftp.FTPHelperImplTest.java')).to eq ({:ut_no=>45})
  end

  it "should return directory" do
    extend PomList
    expect(parent_path('/a/b/c/d/x')).to eq '/a/b/c/d'
  end

  it "should return the nearest pom.xml above path" do
    extend PomList
    expects(:directory?).returns true
    File.expects(:exists?).returns true
    expect(pom_above('/a/b/c')).to eq '/a/b/c/pom.xml'
  end

end

