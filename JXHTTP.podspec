Pod::Spec.new do |s|
  s.name          = 'JXHTTP'
  s.version       = '1.0.3'
  s.source_files  = 'JXHTTP/*.{h,m}'
  s.homepage      = 'http://jxhttp.com'
  s.summary       = 'Networking for iOS and OS X.'
  s.authors       = { 'Justin Ouellette' => 'jstn@jxhttp.com' }
  s.source        = { :git => 'https://github.com/jstn/JXHTTP.git', :tag => "#{s.version}" }
  s.license       = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.weak_frameworks   = 'UIKit'
  s.osx.weak_frameworks   = 'AppKit'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
