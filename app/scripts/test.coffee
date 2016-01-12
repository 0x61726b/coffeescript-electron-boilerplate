electron = require 'electron'
app = electron.app
BrowserWindow = electron.BrowserWindow
crashReporter = require 'crash-reporter'
# ---------------------------
#
# ---------------------------

mainWindow = null

app.on 'window-all-closed', () ->
  app.quit()

app.on 'ready', () ->
  # Menu.setApplicationMenu(appMenu)
  mainWindow = new BrowserWindow
    width: 800
    height: 600
  mainWindow.loadURL('file://' + __dirname + '/app.html')
