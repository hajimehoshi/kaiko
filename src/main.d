module main;

import kaiko.game.application;
import kaiko.game.device;
import kaiko.game.mainscene;
import kaiko.game.mainwindow;
import kaiko.ipc.simplesession;
import kaiko.ipc.server;
import kaiko.ipc.socketclient;
import kaiko.ipc.socketserver;
import kaiko.storage.sessionprocessor;

unittest {
  scope Server!(SessionProcessor!(SimpleSession!SocketClient)) server;
}

import std.stdio;

void main(string[] args) {
  auto mainWindow = new MainWindow!Application;
  auto device = new Device(mainWindow.handle, Application.width, Application.height);
  auto scene = new MainScene();
  try {
    return Application.run(mainWindow.handle, device, scene);
  } catch (ExitException e) {
    return e.status;
  }
}
