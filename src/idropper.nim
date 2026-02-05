# ========================================================================================
#
#                                   iDropper
#                          version 1.0.0 by Mac_Taylor
#
# ========================================================================================

import nim2gtk/[gtk, gdk, glib, gobject]
import nim2gtk/gio except ListStore
import osproc
import std/colors
import std/strutils
import pnm

const cssData =
  """
button.circular {
    border-radius: 50%;
    min-width: 16px;
    min-height: 16px;
    padding: 10px;
}
button.rounded {
    border-radius: 10px;
    border: none;
    min-width: 16px;
    min-height: 16px;
    padding: 10px;
}
button.row {
    border-radius: 10px;
    border: none;
}
list {
    border-radius: 10px;
    border: 1px solid @borders;
}
row {
    border-radius: 10px;
    border: none;
    outline: none;
    box-shadow: none;
    margin: 0;
    padding: 0;
}

"""

proc getPixelColor(): string =
  # Use slurp to get mouse position
  let (output, status) = execCmdEx("slurp -b 00000000 -p")

  let tokens = output.split({' ', ','})
  var x = parseInt(tokens[0])
  var y = parseInt(tokens[1])
  #var d = tokens[2].strip

  # Offset x, y up-left 3 pix
  # workaround for bug in grim
  # causing cursor to always be captured
  if x >= 3:
    x = x - 3

  if y >= 3:
    y = y - 3

  let pos = $x & "," & $y & " 1x1"

  # Use grim to take a 1x1 screenshot
  let cmd = "grim -g \"" & pos & "\" -t ppm - > /tmp/color.ppm"
  discard execCmd(cmd)

  # Read PPM file
  let
    image = readPPMFile("/tmp/color.ppm")
    red = image.data[0]
    green = image.data[1]
    blue = image.data[2]

  # Create a color from RGB
  let color = $rgb(red, green, blue)

  return color

proc onRowClick(button: Button, color: string) =
  let clipboard = getDefaultClipboard(getDefaultDisplay())
  clipboard.setText(color, -1)

proc onRemoveBtn(button: Button, list: ListBox) =
  # Get ListBoxRow from button
  let box = getParent(button)
  let row = cast[ListBoxRow](getParent(box))

  if row != nil:
    list.remove(row)
    row.destroy() # Explicitly destroy the widget to free memory

  echo "remove color"
  #list.showAll()

proc addListItem(list: ListBox, color: string) =
  let row = newListBoxRow()
  row.activatable = false

  # Create main box to hold buttons
  let rowBox = newBox(Orientation.horizontal, 0)

  # Create color button and make it fill
  let colorBtn = newButton()
  colorBtn.hexpand = true
  colorBtn.halign = Align.fill
  colorBtn.relief = ReliefStyle.none
  colorBtn.connect("clicked", onRowClick, color)

  let colorBtnContext = colorBtn.getStyleContext()
  colorBtnContext.addClass("row")

  # Create box to hold widgets for button
  let buttonBox = newBox(Orientation.horizontal, 0)

  let label = newLabel(color)
  label.xalign = 0
  label.halign = Align.start
  label.valign = Align.center

  let colorBox = newBox(Orientation.horizontal, 0)
  colorBox.hexpand = true
  colorBox.marginStart = 10
  colorBox.marginEnd = 10
  colorBox.marginTop = 10
  colorBox.marginBottom = 10

  let colorBoxCss =
    "box.color { background-color: " & color &
    "; border-radius: 10px; border: 1px solid @borders; }"

  let colorBoxProvider = newCssProvider()
  discard colorBoxProvider.loadFromData(colorBoxCss)

  let colorBoxContext = colorBox.getStyleContext()
  colorBoxContext.addProvider(colorBoxProvider, STYLE_PROVIDER_PRIORITY_APPLICATION)
  colorBoxContext.addClass("color")

  # Create remove button
  let removeBtn = newButton()
  removeBtn.setImage(newImageFromIconName("edit-delete-symbolic", IconSize.menu.ord))
  removeBtn.setRelief(ReliefStyle.none)
  #removeBtn.marginStart = 10
  removeBtn.marginEnd = 10
  removeBtn.marginTop = 10
  removeBtn.marginBottom = 10
  removeBtn.connect("clicked", onRemoveBtn, list)

  let removeBtnContext = removeBtn.getStyleContext()
  removeBtnContext.addClass("rounded")

  buttonBox.add(label)
  buttonBox.add(colorBox)
  colorBtn.add(buttonBox)

  rowBox.add(colorBtn)
  rowBox.add(removeBtn)
  row.add(rowBox)

  # Insert row at beginning of list
  list.insert(row, 0)

proc onPickBtn(button: Button, list: ListBox) =
  let color = getPixelColor()

  let clipboard = getDefaultClipboard(getDefaultDisplay())
  clipboard.setText(color, -1)

  # Add color to history list
  list.addListItem(color)
  list.showAll()

proc appActivate(app: Application) =
  let window = newApplicationWindow(app)
  window.title = "iDropper"
  window.defaultSize = (440, 360)
  window.resizable = false

  let headerBar = newHeaderBar()
  headerBar.title = "iDropper"
  headerBar.showCloseButton = true
  headerBar.decorationLayout = ":close"

  let pickBtn = newButton()
  pickBtn.setImage(newImageFromIconName("color-select-symbolic", IconSize.menu.ord))
  headerBar.packStart(pickBtn)

  let cssProvider = getDefaultCssProvider()
  discard cssProvider.loadFromData(cssData)
  addProviderForScreen(
    getDefaultScreen(), cssProvider, STYLE_PROVIDER_PRIORITY_APPLICATION
  )

  let btnContext = pickBtn.getStyleContext()
  btnContext.addClass("circular")

  let scrolledWindow = newScrolledWindow()
  scrolledWindow.hexpand = true
  scrolledWindow.vexpand = false
  #scrolledWindow.minContentHeight = 280
  #scrolledWindow.minContentWidth = 360

  let listBox = newListBox()
  listBox.marginStart = 60
  listBox.marginEnd = 60
  listBox.marginTop = 30
  listBox.marginBottom = 30
  listBox.selectionMode = SelectionMode.none

  pickBtn.connect("clicked", onPickBtn, listBox)

  # Pack the window
  scrolledWindow.add(listBox)
  window.add(scrolledWindow)
  window.setTitlebar(headerBar)
  window.showAll()

proc main() =
  let app = newApplication("org.gtk.idropper")
  app.connect("activate", appActivate)
  discard run(app)

main()
