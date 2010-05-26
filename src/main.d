module main;

import std.stdio;
import kaiko.ipc.simplesession;
import kaiko.ipc.server;
import kaiko.ipc.socketclient;
import kaiko.ipc.socketserver;

unittest {
  static assert(is(SimpleSession!SocketClient));
  static assert(is(Client!SocketServer == SocketClient));
}

void main(string[] args) {
}
