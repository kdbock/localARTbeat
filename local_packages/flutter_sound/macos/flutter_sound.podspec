#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_sound.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sound'
  s.version          = '9.30.0'
  s.summary          = 'A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Pray for Ukraine.'
  s.description      = <<-DESC
A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Pray for Ukraine.
                       DESC
  s.homepage         = 'https://github.com/Canardoux/flutter_sound'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Canardoux' => 'contact@canardoux.xyz' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
