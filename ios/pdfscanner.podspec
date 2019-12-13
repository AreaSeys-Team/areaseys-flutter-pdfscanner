#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'pdfscanner'
  s.version          = '1.0'
  s.summary          = 'PDF scanner plugin for iOS'
  s.description      = <<-DESC
Plugin para el escandeado de imagenes a PDF.
                       DESC
  s.homepage            = 'http://areaseys.com'
  s.license             = { :file => '../LICENSE' }
  s.author              = { 'AREASeys S.L' => 'shoyos@areaseys.com' }
  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'WeScan'
  s.ios.deployment_target = '11.0'
end

