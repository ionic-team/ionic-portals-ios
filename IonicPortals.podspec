Pod::Spec.new do |s|
  s.name = 'IonicPortals'
  s.version = '0.7.3'
  s.summary = 'Ionic Portals'
  s.social_media_url = 'https://twitter.com/capacitorjs'
  s.license = 'Commercial'
  s.homepage = 'https://ionic.io/portals'
  s.ios.deployment_target = '13.0'
  s.authors = { 'Ionic Team' => 'hi@ionicframework.com' }
  s.source = { git: 'https://github.com/ionic-team/ionic-portals-ios.git', tag: s.version.to_s }
  s.source_files = 'Sources/IonicPortals/*.swift'
  s.dependency 'Capacitor', '~> 4.6'
  s.dependency 'IonicLiveUpdates', '>= 0.1.2', '< 0.5.0'
  s.swift_version = '5.4'
end
