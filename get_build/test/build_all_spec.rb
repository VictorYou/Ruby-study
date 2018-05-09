require '../lib/build_all'
require 'mocha/test_unit'

describe "test BuildInfo class to get build hash" do
  it "should get correct build hash" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['nass'])
    hash_list = [{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :duration => '1 hr 55 min'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184332', :change_ids => '184332,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95', :duration => '2 hr 10 min'}]}, {'EXP-component-experimental-test'=>[]}, {'CHECK-component-build-unit-test' => []}]
    flat_list = [{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :duration => '1 hr 55 min'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184332', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95', :duration => '2 hr 10 min'}]
    @tester.instance_eval {@hash_list = hash_list} 
    @tester.expects(:flat_list).returns flat_list
    expect(@tester.all_build).to eq flat_list
  end

  it "should keep only builds after a starting date" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['nass'])
    all_build = [{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :duration => '1 hr 55 min', :date=>Time.new(2018,'Jan',20,05,34,26)}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184332', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95', :duration => '2 hr 10 min', :date=>Time.new(2018,'Feb',20,05,34,26)}]
    @tester.expects(:all_build).returns all_build
    expect(@tester.build_starting('2018-02-01')).to eq [{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184332', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95', :duration => '2 hr 10 min', :date=>Time.new(2018,'Feb',20,05,34,26)}]
  end

  it "should keep only successful builds for analysis" do
    build_starting = [{:result => 'SUCCESS', :module_to_build => 'A'}, {:result => 'FAILURE', :module_to_build => 'B'}]
    expect(BuildAnalyser.valid_build(build_starting)).to eq [{:result => 'SUCCESS', :module_to_build => 'A'}]
  end

  it "should keep only builds with module_to_build" do
    build_starting = [{:result => 'SUCCESS', :module_to_build => 'A'}, {:result => 'SUCCESS', :module_to_build => ''}]
    expect(BuildAnalyser.valid_build(build_starting)).to eq [{:result => 'SUCCESS', :module_to_build => 'A'}]
  end

  it "should keep only shortest check build for each module" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['nass'])
    build_starting = [{:module_to_build => '/workspace/netact/nass/SSS/implementation', :duration => 30, :type => 'CHECK'}, {:module_to_build => '/workspace/netact/nass/SSS/implementation', :duration => 20, :type => 'CHECK'}, {:module_to_build => '/workspace/netact/nass/SMU/implementation', :duration => 30, :type => 'CHECK'}, {:module_to_build => '/workspace/netact/nass/SMU/implementation', :duration => 50, :type => 'CHECK'}]
    BuildAnalyser.expects(:filtered_hash_build).with(build_starting).returns build_starting
    BuildAnalyser.expects(:key).returns :duration
    expect(BuildAnalyser.build_starting(build_starting)).to eq [{:module_to_build => '/workspace/netact/nass/SMU/implementation', :duration => 30, :type => 'CHECK'}, {:module_to_build => '/workspace/netact/nass/SSS/implementation', :duration => 20, :type => 'CHECK'} ]
  end

  it "should filter check hash build" do
    build_starting = [{:module_to_build => '/workspace/netact/nass/SSS/implementation', :type => 'CHECK', :duration => 1}, {:module_to_build => '/workspace/netact/nass/SMU/implementation', :type => 'GATE', :duration => 10}]
    expect(CheckBuildAnalyser.filtered_hash_build(build_starting)).to eq [{:module_to_build => '/workspace/netact/nass/SSS/implementation', :type => 'CHECK', :duration => 1}]
  end

  it "should filter only non 0 gate upgrade hash build" do
    build_starting = [{:module_to_build => '/workspace/netact/nass/SSS/implementation', :type => 'CHECK', :upgrade_duration => 1}, {:module_to_build => '/workspace/netact/nass/SMU/implementation', :type => 'GATE', :upgrade_duration => 10}, {:module_to_build => '/workspace/netact/nass/SMU/implementation', :type => 'GATE', :upgrade_duration => 0}]
    GateBuildAnalyser.expects(:key).returns(:upgrade_duration)
    expect(GateBuildAnalyser.filtered_hash_build(build_starting)).to eq [{:module_to_build => '/workspace/netact/nass/SMU/implementation', :type => 'GATE', :upgrade_duration => 10}]
  end

  it "should return upgrade duration key for gate build analyzer" do
    expect(GateUpgradeBuildAnalyser.key).to eq :upgrade_duration
  end

  it "should return test duration key for gate build analyzer" do
    expect(GateTestBuildAnalyser.key).to eq :test_duration
  end

  it "should return upgrade duration key for exp build analyzer" do
    expect(ExpUpgradeBuildAnalyser.key).to eq :upgrade_duration
  end

  it "should return test duration key for exp build analyzer" do
    expect(ExpTestBuildAnalyser.key).to eq :test_duration
  end

  it "should return duration key for check build analyzer" do
    expect(CheckBuildAnalyser.key).to eq :duration
  end

  it "should get builds for analysis" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['nass'])
    build_starting = [{:module_to_build => 'A'}, {:module_to_build => 'B'}, {:module_to_build => 'C'}, {:module_to_build => 'D'}, {:module_to_build => 'E'}, {:module_to_build => 'F'}, {:module_to_build => 'G'}]
    @tester.instance_eval {@build_starting = build_starting}
    build_valid = [{:module_to_build => 'B'}, {:module_to_build => 'C'}, {:module_to_build => 'D'}, {:module_to_build => 'E'}, {:module_to_build => 'F'}, {:module_to_build => 'G'}]
    build_check = [{:module_to_build => 'B'}]
    build_gate_upgrade = [{:module_to_build => 'C'}]
    build_exp_upgrade = [{:module_to_build => 'D'}]
    build_gate_test = [{:module_to_build => 'E'}]
    build_exp_test = [{:module_to_build => 'F'}]
    BuildAnalyser.expects(:valid_build).with(build_starting).returns build_valid
    CheckBuildAnalyser.expects(:build_starting).with(build_valid).returns build_check
    GateUpgradeBuildAnalyser.expects(:build_starting).with(build_valid).returns build_gate_upgrade
    ExpUpgradeBuildAnalyser.expects(:build_starting).with(build_valid).returns build_exp_upgrade
    GateTestBuildAnalyser.expects(:build_starting).with(build_valid).returns build_gate_test
    ExpTestBuildAnalyser.expects(:build_starting).with(build_valid).returns build_exp_test

    expect(@tester.build_starting_for_analysis).to eq [{:module_to_build => 'B'}, {:module_to_build => 'C'}, {:module_to_build => 'D'}, {:module_to_build => 'E'}, {:module_to_build => 'F'}]

    # original hash list is untouched.
    expect(@tester.build_starting).to eq [{:module_to_build => 'A'}, {:module_to_build => 'B'}, {:module_to_build => 'C'}, {:module_to_build => 'D'}, {:module_to_build => 'E'}, {:module_to_build => 'F'}, {:module_to_build => 'G'}]
  end
end

