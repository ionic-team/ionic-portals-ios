Pod::Spec.new do |s|
  s.name = 'IonicPortals'
  s.version = '0.14.0-rc.0'
  s.summary = 'Ionic Portals'
  s.social_media_url = 'https://twitter.com/capacitorjs'
  s.license = 'Commercial'
  s.homepage = 'https://ionic.io/portals'
  s.ios.deployment_target = '15.0'
  s.authors = { 'Ionic Team' => 'hi@ionicframework.com' }
  s.source = { git: 'https://github.com/ionic-team/ionic-portals-ios.git', tag: s.version.to_s }
  s.source_files = 'Sources/IonicPortals/**/*.swift'
  s.dependency 'Capacitor', '~> 8.0.0'
  s.dependency 'IonicLiveUpdates', '>= 0.5.0', '< 0.6.0'
  s.dependency 'LiveUpdateProvider', '~> 0.1.0-alpha.2'
  s.swift_version = '5.7'
end
