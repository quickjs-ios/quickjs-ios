Pod::Spec.new do |spec|

  spec.name         = "QuickJS_iOS"
  spec.version      = "0.0.7"
  spec.summary      = "QuickJS iOS Bridge"
  spec.description  = <<-DESC
  QuickJS iOS Bridge, you can invoke objc api in javascript, and invoke javascript api in objc.
                   DESC

  spec.homepage     = "https://github.com/quickjs-ios/quickjs-ios"
  spec.license      = "MIT"
  spec.author       = "Sam Chang"
  spec.platform     = :ios, "8.0"
  spec.source       = { :git => "https://github.com/quickjs-ios/quickjs-ios.git", :tag => "#{spec.version}" }

  spec.source_files  = "QuickJS-iOS/Classes", "QuickJS-iOS/QuickJS_iOS.h", "quickjs-2019-08-10/quickjs.c", "quickjs-2019-08-10/bjson.c", "quickjs-2019-08-10/cutils.c", "quickjs-2019-08-10/libbf.c", "quickjs-2019-08-10/libregexp.c", "quickjs-2019-08-10/libunicode.c", "quickjs-2019-08-10/quickjs-libc.c", "quickjs-2019-08-10/*.h"
  spec.public_header_files = "QuickJS-iOS/Classes/**/*.h", "QuickJS-iOS/QuickJS_iOS.h", "quickjs-2019-08-10/quickjs.h", "quickjs-2019-08-10/quickjs-libc.h", "quickjs-2019-08-10/quickjs-atom.h"

  spec.xcconfig = { "OTHER_CFLAGS" => <<-DESC
    $(inherited) -DCONFIG_VERSION=\\"2019-08-10\\"
    DESC
    }

end
