# Package

version       = "1.0.0"
author        = "Mac Taylor"
description   = "A color picker for wayland"
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["idropper"]


# Dependencies
requires "nim >= 2.2.4"
requires "https://github.com/BigMacTaylor/nim2gtk.git"
requires "pnm"

# Foreign Dependencies
foreignDeps = @["libgtk-3-0", "slurp", "grim"]

task release, "Build release":
    exec "nim c -d:release -d:strip --opt:size -o:bin/idropper src/idropper.nim"
