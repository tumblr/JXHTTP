Pod::Spec.new do |s|
  s.name         = 'JXHTTP'
  s.version      = '1.0.0'
  s.author       = { 'Justin Ouellette' => 'jstn@jxhttp.com' }
  s.source_files = '*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.frameworks   = 'Foundation'
  s.ios.weak_frameworks = 'UIKit'
  s.osx.weak_frameworks = 'AppKit'
  s.documentation = {
    :html => 'http://jxhttp.com/docs',
    :appledoc => [
      '--project-name', 'JXHTTP',
      '--project-company', 'JSTN',
      '--docset-copyright', 'Justin Ouellette',
      '--clean-output',
      '--explicit-crossref',
      '--no-repeat-first-par'
      ]}
end
