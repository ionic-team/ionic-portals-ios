# source 'https://github.com/native-portal/podspecs.git'

platform :ios, '14.0'
workspace 'IonicPortals'

pod_project = './IonicPortals/IonicPortals.xcodeproj'

def capacitor_pods
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'Capacitor', :path => '../capacitor/ios'
  pod 'CapacitorCordova', :path => '../capacitor/ios'
  pod 'IonicLiveUpdates'
end

target 'IonicPortals' do
  project pod_project
  capacitor_pods
end

target 'IonicPortalsTests' do
  project pod_project
  capacitor_pods
end
