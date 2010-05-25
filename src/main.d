module main;

import std.stdio;
import kaiko.ipc.simplesession;
import kaiko.ipc.socketclient;

static assert(is(typeof(SimpleSession!SocketClient)));

void main(string[] args) {
}
