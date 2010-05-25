module kaiko.ipc.socketserver;

import std.socket;
import kaiko.ipc.socketclient;

class SocketServer {

  private Socket socket_;
  private ushort port_;
  private SocketClient lastAcceptedClient_;

  public this() {
    this(InternetAddress.PORT_ANY);
  }

  public this(in ushort port) {
    this.socket_ = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    this.socket_.bind(new InternetAddress(port));
    this.socket_.listen(10);
    this.port_ = (cast(InternetAddress)(this.socket_.localAddress)).port;
  }

  public bool accept() {
    if (!this.socket_) {
      return false;
    }
    auto socketSet = new SocketSet(1);
    socketSet.add(this.socket_);
    switch (Socket.select(socketSet, null, null, 0)) {
    case 0:  // timeout
    case -1: // EINTR
      this.lastAcceptedClient_ = null;
      return true;
    default:
      Socket socket = this.socket_.accept();
      assert(socket);
      this.lastAcceptedClient_ = new SocketClient(socket);
      return true;
    }
  }

  public void close() {
    if (this.socket_) {
      this.socket_.shutdown(SocketShutdown.BOTH);
      this.socket_.close();
      this.socket_ = null;
    }
  }

  @property
  public SocketClient lastAcceptedClient() {
    return this.lastAcceptedClient_;
  }

  @property
  public ushort port() const {
    return this.port_;
  }

  @property
  package Socket socket() {
    return this.socket_;
  }

}

unittest {
  auto server = new SocketServer();
  scope (exit) { server.close(); }

  assert(server.accept());
  assert(server.port);
  SocketClient[] clients;
  clients ~= new SocketClient("127.0.0.1", server.port);
  clients ~= new SocketClient("127.0.0.1", server.port);
  clients ~= new SocketClient("127.0.0.1", server.port);
  scope (exit) {
    foreach (client; clients) {
      client.close();
    }
  }

  SocketClient[] clientsInServer;
  clientsInServer.length = clients.length;
  do {
    assert(server.accept());
    clientsInServer[0] = server.lastAcceptedClient;
  } while (!clientsInServer[0]);
  do {
    assert(server.accept());
    clientsInServer[1] = server.lastAcceptedClient;
  } while (!clientsInServer[1]);
  do {
    assert(server.accept());
    clientsInServer[2] = server.lastAcceptedClient;
  } while (!clientsInServer[2]);
  scope (exit) {
    foreach (client; clientsInServer) {
      client.close();
    }
  }
  assert(server.accept());
  assert(!server.lastAcceptedClient);

  assert(clients[0].socket.remoteAddress.toString() == clientsInServer[0].socket.localAddress.toString());
  assert(clients[0].socket.localAddress.toString() == clientsInServer[0].socket.remoteAddress.toString());
  assert(clients[1].socket.remoteAddress.toString() == clientsInServer[1].socket.localAddress.toString());
  assert(clients[1].socket.localAddress.toString() == clientsInServer[1].socket.remoteAddress.toString());
  assert(clients[2].socket.remoteAddress.toString() == clientsInServer[2].socket.localAddress.toString());
  assert(clients[2].socket.localAddress.toString() == clientsInServer[2].socket.remoteAddress.toString());

  clients[0].addDataToSend(cast(const(byte[]))"foo");
  clients[0].addDataToSend(cast(const(byte[]))"bar");
  clients[0].addDataToSend(cast(const(byte[]))"baz");
  assert(clients[0].send());
  {
    byte[] receivedData;
    do {
      assert(clientsInServer[0].receive());
      receivedData ~= clientsInServer[0].lastReceivedData;
    } while (receivedData.length < 9);
    assert("foobarbaz" == receivedData);
    assert(clientsInServer[0].receive());
    assert("" == clientsInServer[0].lastReceivedData);
    assert(clientsInServer[0].receive());
    assert("" == clientsInServer[0].lastReceivedData);
  }
  assert(clients[0].send());
  assert(clientsInServer[0].receive());
  assert("" == clientsInServer[0].lastReceivedData);

  clientsInServer[1].addDataToSend(cast(const(byte[]))"FOO");
  clientsInServer[1].addDataToSend(cast(const(byte[]))"BAR");
  clientsInServer[1].addDataToSend(cast(const(byte[]))"BAZ");
  assert(clientsInServer[1].send());
  {
    byte[] receivedData;
    do {
      assert(clients[1].receive());
      receivedData ~= clients[1].lastReceivedData;
    } while (receivedData.length < 9);
    assert("FOOBARBAZ" == receivedData);
    assert(clients[1].receive());
    assert("" == clients[1].lastReceivedData);
    assert(clients[1].receive());
    assert("" == clients[1].lastReceivedData);
  }
  assert(clientsInServer[1].send());
  assert(clients[1].receive());
  assert("" == clients[1].lastReceivedData);
}

unittest {
  // send empty data
  auto server = new SocketServer();
  scope (exit) { server.close(); }

  auto client = new SocketClient("127.0.0.1", server.port);
  scope (exit) { server.close(); }

  SocketClient clientInServer;
  do {
    assert(server.accept());
    clientInServer = server.lastAcceptedClient;
  } while (!clientInServer);

  assert(client.send());
  client.close();
  assert(!client.send());
}

import std.stdio;

unittest {
  // send big data
  auto server = new SocketServer();
  scope (exit) { server.close(); }

  auto client = new SocketClient("127.0.0.1", server.port);
  scope (exit) { server.close(); }

  SocketClient clientInServer;
  do {
    assert(server.accept());
    clientInServer = server.lastAcceptedClient;
  } while (!clientInServer);

  byte[] sentData;
  sentData.length = 16777216;
  sentData[0..$] = cast(byte)'a';
  client.addDataToSend(sentData);
  assert(client.send());
  
  byte[] receivedData;
  do {
    assert(clientInServer.receive);
    receivedData ~= clientInServer.lastReceivedData;
  } while (receivedData.length < sentData.length);
  assert(sentData == receivedData);
}
