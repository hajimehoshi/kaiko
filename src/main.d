module main;

import std.stdio;
import kaiko.ipc.simplesession;
import kaiko.ipc.server;
import kaiko.ipc.socketclient;
import kaiko.ipc.socketserver;
import kaiko.storage.sessionprocessor;

void main(string[] args) {
  scope Server!(SessionProcessor!(SimpleSession!SocketClient)) server;
}
