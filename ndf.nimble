# Package

version       = "0.3.0"
author        = "Max Skybin"
description   = "Duplicate files finder"
license       = "MIT"
srcDir        = "src"
bin           = @["ndf"]

# Dependencies
requires "nim >= 1.0.4", "docopt >= 0.6.5, murmurhash >= 0.4.0"