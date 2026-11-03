Pod::Spec.new do |s|
  s.name             = 'AppDoorSDK'
  s.version          = '1.0.0'
  s.summary          = 'AppDoor iOS SDK — deferred deep linking & mobile attribution.'
  s.description      = <<-DESC
    Self-hosted deep linking and attribution for iOS — deferred deep links,
    install/last-click attribution, and smart link routing. Open-source
    alternative to Branch.io, AppsFlyer OneLink, and Firebase Dynamic Links.
  DESC
  s.homepage         = 'https://github.com/woosu-xyz/appdoor-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Woosu Gisul. Inc.' => 'https://woosu.xyz' }

  # Source is the public mirror of woosu-xyz/woosu-link (sdks/ios).
  # The monorepo stays private; this mirror exists so CocoaPods can clone the
  # source at the tag. Paths are relative to the mirror root. Tag: v<version>.
  s.source           = {
    :git => 'https://github.com/woosu-xyz/appdoor-ios.git',
    :tag => "v#{s.version}"
  }

  s.ios.deployment_target = '16.0'
  s.swift_version    = '5.9'

  s.source_files     = 'Sources/AppDoorSDK/**/*.swift'
  s.resource_bundles = {
    'AppDoorSDK' => ['Sources/AppDoorSDK/Resources/PrivacyInfo.xcprivacy']
  }
end
