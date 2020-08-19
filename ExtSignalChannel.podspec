Pod::Spec.new do |s|
  s.name         = "ExtSignalChannel"
  s.version      = "0.0.1"
  s.summary      = "Send signal to listeners"
  s.homepage     = "https://github.com/Pn-X/ExtSignalChannel"
  s.license      = "MIT" 
  s.author       = { "pn-x" => "pannetez@163.com" }
  s.source       = { :git => "https://github.com/Pn-X/ExtSignalChannel.git", :tag => "#{s.version}" }
  s.source_files  = "Classes", "Classes/**/*"
  s.exclude_files = "Classes/Exclude"
  s.ios.deployment_target = '9.0'
end