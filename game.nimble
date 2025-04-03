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
requires "nimja"
requires "naylib >= 24.49.0"
requires "vmath"
requires "chroma"
requires "unroll"

import std/distros
if detectOs(Windows):
 foreignDep "openjdk"
 foreignDep "wget"
elif detectOs(Ubuntu):
 foreignDep "default-jdk"

# Tasks
include "build_android.nims"
include "export_icon.nims"