# Package

version       = "0.1.0"
author        = "Zumi Daxuya"
description   = "A new awesome nimble package"
license       = "WTFPL"
skipDirs      = @["src"]

# Dependencies

requires "nim >= 1.6.0"
requires "wNim#4dc3afd"
requires "binstreams#4715f6c"

# Tasks

import strformat

let
    toolNames = [
        "GBCompatEd", # toggles GBC compatibility on and off
        #"RunShoesGBC" # adds or removes Running Shoes
    ]

    mmFlag = when (NimMajor > 1):
            "--mm:arc"
        else: "--gc:arc"

    mingwFlag = when defined(mingw): "-d:mingw" else: ""

    resCompiler = "i686-w64-mingw32-windres"
    resDir = "src/res"


task makeRes, "make Windows resources":
    for tool in toolNames:
        exec fmt"{resCompiler} -O coff {resDir}/{tool}.rc {resDir}/{tool}.res"

task makeDevel, "make development binaries":
    makeResTask()
    for tool in toolNames:
        selfExec fmt"c {mmFlag} {mingwFlag} --app:gui -d:useWinXP --cpu:i386 -d:{tool} -o:{tool}.exe src/main.nim"

task makeRelease, "make release binaries":
    makeResTask()
    for tool in toolNames:
        selfExec fmt"""c {mmFlag} {mingwFlag} --app:gui -d:useWinXP --cpu:i386 -d:{tool} -o:{tool}.exe --passC:"-flto -O3 -ffunction-sections -fdata-sections" --passL:"-flto -O3 -s -Wl,--gc-sections" -d:release src/main.nim"""

task clean, "clean up generated binaries":
    for tool in toolNames:
        rmFile fmt"{tool}.exe"
        rmFile fmt"{resDir}/{tool}.res"
