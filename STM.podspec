#
# Be sure to run `pod lib lint STM.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "STM"
  s.version          = "0.0.26"
  s.summary          = "Shout To Me iOS SDK"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
      An iOS SDK that can be used to consume the Shout to Me cloud services.
                       DESC

  s.homepage         = "https://github.com/ShoutToMe/stm-sdk-ios"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Tyler Clemens" => "tyler@shoutto.me" }
  s.source           = { :git => "https://github.com/ShoutToMe/stm-sdk-ios.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/shout_to_me'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'STM' => ['Pod/Assets/*.{png,xib,caf}']
  }
  #s.public_header_files = 'Pod/Classes/Public/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
