Pod::Spec.new do |spec|

  spec.name         = "QuickJS-iOS"
  spec.version      = "0.0.4"
  spec.summary      = "QuickJS iOS Bridge"
  spec.description  = <<-DESC
  QuickJS iOS Bridge, you can invoke objc api in javascript, and invoke javascript api in objc.
                   DESC

  spec.homepage     = "https://github.com/quickjs-ios/quickjs-ios"
  spec.license      = "MIT"
  spec.author       = "Sam Chang"
  spec.platform     = :ios, "8.0"
  spec.source       = { :git => "https://github.com/quickjs-ios/quickjs-ios.git", :tag => "#{spec.version}" }

  spec.source_files  = "QuickJS-iOS/Classes", "QuickJS-iOS/QuickJS-iOS.h", "quickjs-2019-07-28/quickjs.c", "quickjs-2019-07-28/bjson.c", "quickjs-2019-07-28/cutils.c", "quickjs-2019-07-28/libbf.c", "quickjs-2019-07-28/libregexp.c", "quickjs-2019-07-28/libunicode.c", "quickjs-2019-07-28/quickjs-libc.c", "quickjs-2019-07-28/*.h"
  spec.public_header_files = "QuickJS-iOS/Classes/**/*.h", "QuickJS-iOS/QuickJS-iOS.h", "quickjs-2019-07-28/quickjs.h", "quickjs-2019-07-28/quickjs-libc.h", "quickjs-2019-07-28/quickjs-atom.h"

  spec.xcconfig = { "OTHER_CFLAGS" => <<-DESC
    $(inherited) -DCONFIG_VERSION=\\"2019-07-28\\"
    DESC
    }

end
