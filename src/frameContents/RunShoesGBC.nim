import wNim/[
  wApp, wPanel, wMacros, wCheckBox, wStaticBox
]

type
  wMainContent* = ref object of wPanel

wClass(wMainContent of wPanel):
  proc init(self: wMainContent, parent: wWindow) =
    wPanel(self).init(parent=parent)

    let
      frmInfo = self.StaticBox(label="ROM info")
      frmActions = self.StaticBox(label="Actions")

      chkShoes = frmActions.CheckBox(label="Make movement speed less shit")

    self.autolayout """
    spacing:4
    H:|-[frmInfo]-[frmActions(frmInfo)]-16-|
    V:|[frmInfo(self.height-170)]|
    V:|[frmActions(self.height-170)]|
    """

    frmActions.autolayout """
    H:|[chkShoes]|
    V:|~[chkShoes]~|
    """

export MainContent
