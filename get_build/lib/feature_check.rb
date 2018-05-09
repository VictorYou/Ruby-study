class FeatureCheck
  attr_reader :feature
  attr_reader :id_arr

  def initialize
    @feature = {}
    @id_arr = ['1234', '4567', '3214']

    # initialize all features to be off be default
    @id_arr.each { |id| @feature.merge!({id=>'off'}) }
  end

  def current_release
    '18A'
  end

  def set_feature
    if current_release == '18A'  # open function for 18A
      @feature['4567'] = 'on'    # for comparing modules to build
    end
    set_config
  end

  def set_config
    if @feature['4567'] == 'on'
      BuildAborted.class_variable_set(:@@CONFIG_COMPARE_MODULES_TO_BUILD, true)
    else  
      BuildAborted.class_variable_set(:@@CONFIG_COMPARE_MODULES_TO_BUILD, false)
    end

#    if BuildInfo::CONFIG_PARSE_BUILD_INFO == 'regexp'
#      BuildInfo.send(:define_method, 'parse_build_info') do |arg|
#        parse_build_info_with_regexp arg
#      end  
#    else
#      BuildInfo.send(:define_method, 'parse_build_info') do |arg|
#        parse_build_info_with_nokogiri arg
#      end
#    end
#    if BuildInfo::CONFIG_GET_BUILD_URL == 'text'
#      BuildInfo.singleton_class.send(:define_method, 'get_build_url') do |arg, &block|
#        get_build_url_text arg, &block
#      end
#    else 
#      BuildInfo.singleton_class.send(:define_method, 'get_build_url') do |arg, &block|
#        get_build_url_html arg, &block
#      end
#    end
  end
end
