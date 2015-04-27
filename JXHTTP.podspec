Pod::Spec.new do |s|
  s.name          = 'JXHTTP'
  s.version       = '2.0.0'
  s.source_files  = 'JXHTTP/*.{h,m}'
  s.homepage      = 'http://justinouellette.com'
  s.summary       = 'Networking for iOS and OS X.'
  s.authors       = { 'Justin Ouellette' => 'justin.ouellette@gmail.com',
                      'Bryan Irace' => 'bryan.irace@gmail.com' }
  s.platform      = :ios, '5.0'
  s.source        = { :git => 'https://github.com/jstn/JXHTTP.git', :tag => "#{s.version}" }
  s.license       = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.weak_frameworks   = 'UIKit'
  s.ios.deployment_target = '5.0'
end
