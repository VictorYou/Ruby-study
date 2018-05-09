require '../lib/build_res_id'
require 'mocha/test_unit'

describe "test BuildResId class to get build res_id" do
  it "should return build url and res_id" do
    @tester = BuildResId.new(['eslinb86.emea.ms-net.net'], ['GATE-med_core3-component-build-deploy-test'])

    expect(@tester.get_res_id([{'GATE-nass-component-build-deploy-test'=>[{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184333', :change_ids => '184333,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.96'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :module_to_build => '/workspace/netact/nass/SMU/implementation', :change => '184332', :change_ids => '184332,1', :result => 'SUCCESS', :end_time => '10:29:39', :res_id => 'nass/smu_platform1_git/18.0.0.95'}]}])).to eq ([{:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1047', :res_id => 'nass/smu_platform1_git/18.0.0.96'}, {:url => 'https://eslinb86.emea.ms-net.net:8080/job/GATE-nass-component-build-deploy-test/1046', :res_id => 'nass/smu_platform1_git/18.0.0.95'}])
  end
end

