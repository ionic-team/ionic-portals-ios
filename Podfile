# source 'https://github.com/native-portal/podspecs.git'

platform :ios, '14.0'
workspace 'IonicPortals'

pod_project = './IonicPortals/IonicPortals.xcodeproj'

def capacitor_pods
  use_frameworks!
  pod 'Capacitor'
  pod 'CapacitorCordova'
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

target 'IonicPortalsObjcTests' do
  project pod_project
  capacitor_pods
end
