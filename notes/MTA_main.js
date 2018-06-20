//handle setupevents as quickly as possible
// This will help us with the installation and also create shortcuts for us.
const setupEvents = require('./installscripts/squirrel/setupEvents')
if (setupEvents.handleSquirrelEvent()) {
  // squirrel event handled and app will exit in 1000ms, so don't do anything else
}

const electron = require('electron')
const { app, Menu, Tray, ipcMain } = require('electron')
const BrowserWindow = electron.BrowserWindow
const path = require('path')
const url = require('url')
const config = require('./scripts/config.js');

// Keep a global reference of the window and tray objects, if you don't, the window and tray notificiation will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow
let tray

function createWindow() {

  const windowProps = {
    width: 1250,
    height: 800,
    minWidth: 1250,
    minHeight: 800
  }

  // Get display props to show BrowserWindow in a proportional size
  const display = electron.screen.getPrimaryDisplay();
  if (display.size.height < windowProps.minHeight) {
    windowProps.height = windowProps.minHeight = display.size.height * 0.8;
  }
  if (display.size.width < windowProps.minWidth) {
    windowProps.width = windowProps.minWidth = display.size.width * 0.8;
  }

  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: windowProps.width,
    height: windowProps.height,
    minHeight: windowProps.minHeight,
    minWidth: windowProps.minWidth,
    icon: __dirname + '/stylesheets/css/brand/favicon/ge-monogram-blue.png',
    webPreferences: {
      devTools: config.dev
    },
    show: false
  });

  // Open the DevTools
  if (config.dev) {
    mainWindow.webContents.openDevTools();
  }

  // Remove menu from application.
  mainWindow.setMenu(null);

  // and load the index.html of the app.
  mainWindow.loadURL(url.format({
    pathname: path.join(__dirname, 'index.html'),
    protocol: 'file:',
    slashes: true
  }));

  // Emitted when the window is closed.
  mainWindow.on('closed', function () {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null
  });

  // When close is clicked from context menus (titlebar, taskbar) or
  // or from the close button then the program removes the taskbar icon
  // and minimize the program to the system tray. The user can then
  // open the app from the tray.
  mainWindow.on('close', function (event) {
    if (!app.isQuiting) {

      if (config.dev) {
        app.quit();
      } else {
        event.preventDefault();
        mainWindow.hide();

        if (closeNotificationCounter === 0) {
          if (process.platform !== 'darwin') {
            tray.displayBalloon({
              title: 'MyTech Assistant Is Still Running',
              content: 'MyTech Assistant will continue to run so that you can receive notifications. Click the MyTech Assistant tray icon to display the application again.'
            });
          }
          else {
            // TODO: find the right api call for MAC
          }

          closeNotificationCounter = 1;
        }
      }
    }
    return false;
  });

  var closeNotificationCounter = 0;

  // Initialze SystemTray Functionality
  if (process.platform !== 'darwin') {
    tray = new Tray(__dirname + '/stylesheets/css/brand/favicon/ge-monogram-blue.ico');
    tray.setToolTip('MyTech Assistant');

    tray.on('click', () => {
      if (!mainWindow.isVisible())
        mainWindow.show();
    });

    mainWindow.on('show', () => {
      tray.setHighlightMode('always');
    });

    mainWindow.on('hide', () => {
      tray.setHighlightMode('never');
    });
  }
}

// Someone tried to run a second instance, we should focus our window.
const isSecondInstance = app.makeSingleInstance((commandLine, workingDirectory) => {
  if (mainWindow) {
    if (mainWindow.isMinimized()) mainWindow.restore()
    mainWindow.focus()
  }
})

// Kill second instance
if (isSecondInstance) {
  app.quit();
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow)

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit();
  }
})

app.on('activate', function () {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  mainWindow.show();
})

// IPC event: detect if window is visible
ipcMain.on('window.isVisible', (event, arg) => {
  event.returnValue = mainWindow.isVisible();
})

// IPC event: detect if window is focused
ipcMain.on('window.isFocused', (event, arg) => {
  event.returnValue = mainWindow.isFocused();
})

// IPC event: detect if window is focused
ipcMain.on('window.show', (event, arg) => {
  mainWindow.show();
  event.returnValue = null;
})
