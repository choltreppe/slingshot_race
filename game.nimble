# Package
version       = "1.0.0"
author        = "Joel Lienhard"
description   = "A mobile game"
license       = "License"
srcDir        = "src"
binDir        = "desktop"
namedBin      = {"main": "game"}.toTable

# Dependencies
requires "nim >= 2.3.1"
requires "fusion"
requires "naylib >= 24.49.0"
requires "vmath"