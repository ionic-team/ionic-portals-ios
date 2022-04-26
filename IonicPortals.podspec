Pod::Spec.new do |s|
  s.name = 'IonicPortals'
  s.version = '0.5.2'
  s.summary = 'Ionic Portals'
  s.social_media_url = 'https://twitter.com/capacitorjs'
  s.license = 'Commercial'
  s.homepage = 'https://ionic.io/portals'
  s.ios.deployment_target  = '14.0'
  s.authors = { 'Ionic Team' => 'hi@ionicframework.com' }
  s.source = { :git => 'https://github.com/ionic-team/ionic-portals-ios.git', :tag => s.version.to_s }
  s.source_files = 'IonicPortals/IonicPortals/*.{swift,h,m}'
  s.resources = ['IonicPortals/IonicPortals/**/*.{xib,xcassets,svg}']
  s.dependency 'Capacitor'
  s.dependency 'IonicLiveUpdates'
  s.swift_version = '5.4'
end
