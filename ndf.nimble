# Package

version       = "0.4.0"
author        = "Max Skybin"
description   = "Duplicate files finder"
license       = "MIT"
srcDir        = "src"
bin           = @["ndf"]

# Dependencies
requires "nim >= 1.4.2", "docopt >= 0.6.5, murmurhash >= 0.4.0"