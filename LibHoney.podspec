
Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "LibHoney"
  s.version      = "1.0.0"
  s.license      = "Apache License, Version 2.0"
  s.summary      = "Swift library for sending events to Honeycomb."

  s.homepage     = "https://github.com/honeycombio/LibHoney-Cocoa"
  s.social_media_url   = "http://twitter.com/honeycombio"
  s.authors            = { "Honeycomb" => "support@honeycomb.io" }

  s.ios.deployment_target = "10.0"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/honeycombio/LibHoney-Cocoa.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "Sources/**/*.swift"
  s.exclude_files = "Tests/**/*.swift"

  s.dependency "Alamofire", "~> 4.5"

end
