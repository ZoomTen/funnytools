import wNim/[
  wApp, wPanel, wMacros, wCheckBox, wStaticBox, wStaticText,
  wFileDialog, wMessageDialog
]

import binstreams
import strutils

type
  wMainContent* = ref object of wPanel
    chkColor: wCheckBox
    #[
      pandocs say that $C0 == $80 when it comes
      to CGB checking but there's an undocumented
      PGB mode so I won't bother
    ]#
    chkSgb: wCheckBox

    romFile: FileStream
    currentRomName: string

    frmInfo: wStaticBox
    frmActions: wStaticBox

    lblRomTitleValue: wStaticText
    lblRomCodeValue: wStaticText
    lblRomLicenseeValue: wStaticText
    lblRomDestinationValue: wStaticText

wClass(wMainContent of wPanel):
  proc setupFrmInfo(self: wMainContent)
  proc init(self: wMainContent, parent: wWindow) =
    wPanel(self).init(parent=parent)

    self.frmInfo = self.StaticBox(label="ROM info")
    self.frmActions = self.StaticBox(label="Actions")

    let
      frmInfo = self.frmInfo
      frmActions = self.frmActions

    self.chkColor = frmActions.CheckBox(label="Enable Game Boy Color compat")
    self.chkSgb = frmActions.CheckBox(label="Enable Super Game Boy compat")

    let
      chkColor = self.chkColor
      chkSgb = self.chkSgb

    self.autolayout """
    spacing:4
    H:|-[frmInfo]-[frmActions(frmInfo)]-16-|
    V:|[frmInfo(self.height-170)]|
    V:|[frmActions(self.height-170)]|
    """

    frmActions.autolayout """
    H:|[chkColor]|
    H:|[chkSgb]|
    V:|~[chkColor][chkSgb]~|
    """

    self.setupFrmInfo

  proc setupFrmInfo(self: wMainContent) =
    self.lblRomTitleValue = self.frmInfo.StaticText(label="No ROM Loaded")
    self.lblRomCodeValue = self.frmInfo.StaticText(label="")
    self.lblRomLicenseeValue = self.frmInfo.StaticText(label="")
    self.lblRomDestinationValue = self.frmInfo.StaticText(label="")

    let
      lblRomTitle = self.frmInfo.StaticText(label="Title:")
      lblRomCode = self.frmInfo.StaticText(label="Code:")
      lblRomLicensee = self.frmInfo.StaticText(label="Licensee:")
      lblRomDestination = self.frmInfo.StaticText(label="Region:")

      lblRomTitleValue = self.lblRomTitleValue
      lblRomCodeValue = self.lblRomCodeValue
      lblRomLicenseeValue = self.lblRomLicenseeValue
      lblRomDestinationValue = self.lblRomDestinationValue

    # pain
    self.frmInfo.autolayout """
    H:|[lblRomTitle(==lblRomTitleValue/2)][lblRomTitleValue]|
    H:|[lblRomCode(==lblRomTitleValue/2)][lblRomCodeValue]|
    H:|[lblRomLicensee(==lblRomLicenseeValue/2)][lblRomLicenseeValue]|
    H:|[lblRomDestination(==lblRomDestinationValue/2)][lblRomDestinationValue]|
    V:|[lblRomTitleValue(==lblRomCodeValue)][lblRomCodeValue(==lblRomLicenseeValue)][lblRomLicenseeValue(==lblRomDestinationValue)][lblRomDestinationValue]~|
    V:|[lblRomTitle(==lblRomCode)][lblRomCode(==lblRomLicensee)][lblRomLicensee(==lblRomDestination)][lblRomDestination]~|
    """

  proc openFileAction*(self: wMainContent): bool =
    let dlg = self.FileDialog(
        wildcard="Game Boy ROM (*.gb,*.gbc,*.sgb)|*.gb;*.gbc;*.sgb",
        style=wFdOpen or wFdFileMustExist
    )
    if dlg.showModal == wIdOk:
      self.romFile = newFileStream(dlg.path, littleEndian, fmReadWriteExisting)
      self.currentRomName = dlg.path
      self.romFile.setPosition 0x134
      self.lblRomTitleValue.label = self.romFile.readStr(11)
      self.lblRomCodeValue.label = self.romFile.readStr(4)
      self.romFile.setPosition 0x14b
      let oldLicenseCode = self.romFile.read(uint8)
      self.romFile.setPosition 0x144
      self.lblRomLicenseeValue.label = if oldLicenseCode == 0x33:
          self.romFile.readStr(2) & " (new)"
        else:
          oldLicenseCode.toHex(2)
      self.romFile.setPosition 0x14a
      self.lblRomDestinationValue.label =
        if self.romFile.read(bool): "International"
        else: "Japan"
      # SGB flag
      self.romFile.setPosition 0x146
      self.chkSgb.value = (self.romFile.read(uint8) == 0x03)
      # CGB flag
      self.romFile.setPosition 0x143
      self.chkColor.value = bool(self.romFile.read(uint8) and 0x80)
      return true
    return false

  proc saveFileGeneric(self: wMainContent, fileName: string) =
    self.romFile.setPosition 0, sspEnd
    let contentLen = self.romFile.getPosition
    var contentCopy = newSeq[byte](contentLen+1)
    self.romFile.setPosition 0, sspSet
    self.romFile.read(contentCopy, startIndex=1, numValues=contentLen)

    contentCopy[0x146 + 1] = # why Natural?
      if self.chkSgb.getValue: 3
      else: 0

    contentCopy[0x143 + 1] =
      if self.chkColor.getValue: 0x80
      else: 0

    var satChksum: uint8 = 0
    for i in (0x134+1)..(0x14c+1):
      satChksum = satChksum - contentCopy[i] - 1

    contentCopy[0x14d+1] = satChksum

    let copyToSave = newFileStream(fileName, littleEndian, fmWrite)
    copyToSave.write(contentCopy, startIndex=1, numValues=contentLen)

    discard self.MessageDialog(
        message="File successfully saved!",
        caption="Saved",
        style=wIconAsterisk
    ).showModal()

  proc saveFileAction*(self: wMainContent) =
    self.saveFileGeneric(self.currentRomName)

  proc saveFileAsAction*(self: wMainContent) =
    let dlg = self.FileDialog(
        wildcard="Game Boy ROM (*.gb,*.gbc,*.sgb)|*.gb;*.gbc;*.sgb",
        style=wFdSave or wFdOverwritePrompt
    )
    if dlg.showModal() == wIdOk:
      self.saveFileGeneric(dlg.path)

export MainContent
