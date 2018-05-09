require '../lib/build_aborted'
require 'mocha/test_unit'

describe "test AllBuildInfo class to get build res_id" do
  it "should return aborted build url when former build is aborted at the same time for a different module" do
    BuildAborted.class_variable_set(:@@CONFIG_COMPARE_MODULES_TO_BUILD, true)
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['GATE-med_core3-component-build-deploy-test'])
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    expect(@tester.get_aborted_build([{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184332,1 184333,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :duration => '1 min 15 sec'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU1/implementation', :change => '184332', :change_ids => '184332,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95'}]}])).to eq ([{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :duration => '1 min 15 sec', :module=>"/workspace/netact/nass/SMU/implementation", :previous_url=> "https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046", :previous_module=>"/workspace/netact/nass/SMU1/implementation"}])
  end

  it "should return aborted build url when former build is failure at the same time for a different module" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['GATE-med_core3-component-build-deploy-test'])
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    expect(@tester.get_aborted_build([{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184332,1 184333,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96', :duration => '1 min 15 sec'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU1/implementation', :change => '184332', :change_ids => '184332,1', :result => 'FAILURE', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95'}]}])).to eq ([{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :duration => '1 min 15 sec', :module=>"/workspace/netact/nass/SMU/implementation", :previous_url=> "https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046", :previous_module=>"/workspace/netact/nass/SMU1/implementation"}])
  end

  it "should not return aborted build url when current build does not contain former builds' change id" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['GATE-med_core3-component-build-deploy-test'])
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    expect(@tester.get_aborted_build([{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU1/implementation', :change => '184332', :change_ids => '184332,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95'}]}])).to eq ([])
  end


  it "should not return aborted build url when former build is successful" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['GATE-med_core3-component-build-deploy-test'])
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    expect(@tester.get_aborted_build([{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU1/implementation', :change => '184332', :change_ids => '184332,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95'}]}])).to eq ([])
  end

  it "should not return aborted build url when former build is the same module" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['GATE-med_core3-component-build-deploy-test'])
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    expect(@tester.get_aborted_build([{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184332', :change_ids => '184332,1', :result => 'FAILURE', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95'}]}])).to eq ([])
  end

  it "should not return aborted build url when former build does not end at the same time" do
    @tester = AllBuildInfo.new(['eslinb86.emea.ms-net.net'], ['GATE-med_core3-component-build-deploy-test'])
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    @tester.expects(:log).returns(true)
    expect(@tester.get_aborted_build([{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'ABORTED', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU1/implementation', :change => '184332', :change_ids => '184332,1', :result => 'ABORTED', :end_time => '10:29:40', :res_id => 'nass/smu_platform1_git/18.0.0.95'}]}])).to eq ([])
  end
end

