Pod::Spec.new do |s|
  s.name          = 'JXHTTP'
  s.version       = '1.0.0'
  s.source        = { :git => 'git://github.com/jstn/JXHTTP.git', :tag => '1.0.0' }
  s.authors       = { 'Justin Ouellette' => 'jstn@jxhttp.com' }
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage      = 'http://jxhttp.com/'
  s.summary       = 'networking for iOS and OS X'
  s.source_files  = 'JXHTTP/*.{h,m}'
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.weak_frameworks   = 'UIKit'
  s.osx.weak_frameworks   = 'AppKit'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.documentation = {
    :html => 'http://jxhttp.com/docs/html',
    :appledoc => [
      '--company-id', 'com.jxhttp',
      '--project-name', 'JXHTTP',
      '--project-company', 'JSTN',
      '--project-version', '1.0.0',
      '--ignore', 'example',
      '--ignore', 'docs',
      '--no-repeat-first-par',
      '--explicit-crossref',
      '--clean-output'
    ]
  }
end
