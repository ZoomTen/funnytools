#{.define:GBCompatEd.} # nimsuggest IDE hint

import wNim/[
  wApp, wFrame, wMacros, wPanel, wStaticBitmap, wBitmap,
  wMenuBar, wMenu, wStaticText, wStaticLine, wWindow, wFont, wButton
]

import std/strformat

when defined(GBCompatEd):
  import ./frameContents/GBCompatEd
  {.link:"res/GBCompatEd.res".}
elif defined(RunShoesGBC):
  import ./frameContents/RunShoesGBC
else:
  {.error:"Which one do you wanna build?".}

const headerImage =
  when defined(GBCompatEd):
    staticRead("headerImages/GBCompatEd.png")
  elif defined(RunShoesGBC):
    staticRead("headerImages/RunShoesGBC.png")
  else: ""

const
  appName =
    when defined(GBCompatEd): "Toggle Game Boy Color compatibility tool"
    elif defined(RunShoesGBC): "Add Running Shoes to Pokemon Gold program"
    else: "unknown"
  appDesc =
    when defined(GBCompatEd):
      "Toggles GBC/SGB/GB-only compatibility modes."
    elif defined(RunShoesGBC):
      "Enables or disables Running Shoes in Pokemon Gold and Silver."
    else:
      "No description"
  appSize: wSize =
    when defined(GBCompatEd): (420,310)
    elif defined(RunShoesGBC): (420,280)
    else: (400,400)

type
  MenuId = enum
    mOpenRom = 100
    mSaveRom
    mSaveRomAs
    mExit
    mAbout

wClass(wAbout of wFrame):
  proc init(self: wAbout, owner: wWindow, title: string) =
    wFrame(self).init(
      title=fmt"About {title}",
      size=(400, 200),
      style=wFrameToolWindow or wSystemMenu
    )
    self.enableCloseButton

    let
      canvas = self.Panel
      aboutHeader = canvas.Panel
      aboutH1 = aboutHeader.StaticText(
        label=appName, style=wAlignMiddle or wAlignLeft
      )
      aboutP = canvas.StaticText(
        label=appDesc
      )
      line = canvas.StaticLine
      line2 = canvas.StaticLine
      okButton = canvas.Button(label="OK")

    aboutHeader.backgroundColor = wWhite
    aboutH1.backgroundColor = wWhite
    aboutH1.font = Font(
      faceName="tahoma", pointSize=11.25, weight=wFontWeightBold
    )

    self.autolayout """
    HV:|[canvas]|
    """

    canvas.autolayout """
    spacing:10
    H:|[aboutHeader]|
    H:|-[aboutP]-|
    H:|~[okButton(80)]-|
    V:|[aboutHeader(64)][line]-[aboutP]~[line2]-[okButton]-|
    """

    aboutHeader.autolayout """
    spacing:10
    H:|-[aboutH1]-|
    V:|[aboutH1]|
    """

    self.wEvent_Close do ():
      self.endModal

    okButton.wEvent_Button do ():
      self.close

    self.showModal
    self.delete

type
  wAppFrame = ref object of wFrame
    menuFile: wMenu
    menuHelp: wMenu

wClass(wAppFrame of wFrame):
  proc init(self: wAppFrame, title: string, size: wSize) =
    wFrame(self).init(
      title=title,
      size=size,
      style=wDefaultDialogStyle or wMinimizeBox or wSystemMenu
    )

    let
      canvas = self.Panel
      header = self.StaticBitmap(bitmap=Bitmap(headerImage))
      menubar = self.MenuBar

    self.menuFile = menubar.Menu "&File"
    self.menuHelp = menubar.Menu "&Help"

    self.menuFile.append mOpenRom, "&Open ROM..."
    self.menuFile.append mSaveRom, "&Save ROM..."
    self.menuFile.append mSaveRomAs, "Save ROM &As..."
    self.menuFile.appendSeparator
    self.menuFile.append mExit, "E&xit"

    self.menuHelp.append mAbout, "&About"

    self.menuFile.disable mSaveRom
    self.menuFile.disable mSaveRomAs

    let
      contents = canvas.MainContent
      line = canvas.StaticLine(
        style=wLiHorizontal
      )
      copyinfo = canvas.StaticText(
        label="©2023 Zumi", style=wAlignCentre
      )

    self.autolayout """
    H:|[canvas]|
    H:|[header]|
    V:|[header(100)][canvas]|
    """

    canvas.autolayout """
      spacing:4
      H:|[line]|
      H:|[copyinfo]|
      H:|-[contents]-|
      V:|-[contents]-[line]-[copyinfo]|
    """

    self.mExit do ():
      self.close

    self.mAbout do ():
      About(self, appName)

    self.mOpenRom do ():
      if contents.openFileAction:
        self.menuFile.enable mSaveRom
        self.menuFile.enable mSaveRomAs

    self.mSaveRom do ():
      contents.saveFileAction

    self.mSaveRomAs do ():
      contents.saveFileAsAction

when isMainModule:
  let
    app = App(wSystemDpiAware)
    appFrm = AppFrame(appName, appSize)

  appFrm.show
  app.mainLoop
