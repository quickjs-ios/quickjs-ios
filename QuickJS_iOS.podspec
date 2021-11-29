Pod::Spec.new do |spec|

  spec.name         = "QuickJS_iOS"
  spec.version      = "0.0.8"
  spec.summary      = "QuickJS iOS Bridge"
  spec.description  = <<-DESC
  QuickJS iOS Bridge, you can invoke objc api in javascript, and invoke javascript api in objc.
                   DESC

  spec.homepage     = "https://github.com/quickjs-ios/quickjs-ios"
  spec.license      = "MIT"
  spec.author       = "Sam Chang"
  spec.platform     = :ios, "8.0"
  spec.source       = { :git => "https://github.com/quickjs-ios/quickjs-ios.git", :tag => "#{spec.version}", :submodules => true }

  spec.source_files  = "QuickJS-iOS/Classes", "QuickJS-iOS/QuickJS_iOS.h", "quickjs/quickjs.c", "quickjs/bjson.c", "quickjs/cutils.c", "quickjs/libbf.c", "quickjs/libregexp.c", "quickjs/libunicode.c", "quickjs/quickjs-libc.c", "quickjs/*.h"
  spec.public_header_files = "QuickJS-iOS/Classes/**/*.h", "QuickJS-iOS/QuickJS_iOS.h", "quickjs/quickjs.h", "quickjs/quickjs-libc.h", "quickjs/quickjs-atom.h"

  spec.xcconfig = { "OTHER_CFLAGS" => <<-DESC
    $(inherited) -DCONFIG_VERSION=\\"2021-03-27\\"
    DESC
    }

end
