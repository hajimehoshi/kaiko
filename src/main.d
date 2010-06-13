module main;

import kaiko.game.application;
import kaiko.game.device;
import kaiko.game.mainwindow;
import kaiko.scenes.mainscene;
import kaiko.ipc.simplesession;
import kaiko.ipc.server;
import kaiko.ipc.socketclient;
import kaiko.ipc.socketserver;
import kaiko.storage.sessionprocessor;

unittest {
  scope Server!(SessionProcessor!(SimpleSession!SocketClient)) server;
}

import std.stdio;

int main(string[] args) {
  auto application = Application.instance;
  const mainWindow = new MainWindow(application.width, application.height);
  auto device = new Device(mainWindow.handle, application.width, application.height);
  auto scene = new MainScene();
  try {
    application.run(mainWindow.handle, device, scene);
    return 0;
  } catch (ExitException e) {
    return e.status;
  }
}
