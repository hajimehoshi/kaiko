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

  public this(ushort port) {
    this.socket_ = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    this.socket_.bind(new InternetAddress(port));
    this.socket_.listen(10);
    this.port_ = (cast(InternetAddress)(this.socket_.localAddress)).port;
  }

  public bool accept() {
    if (!this.socket_) {
      return false;
    }
    this.socket_.blocking = false;
    Socket socket;
    try {
       socket = this.socket_.accept();
    } catch (SocketAcceptException) {
      this.lastAcceptedClient_ = null;
      return true;
    }
    assert(socket);
    this.lastAcceptedClient_ = new SocketClient(socket);
    return true;
  }

  public void close() {
    if (this.socket_) {
      this.socket_.shutdown(SocketShutdown.BOTH);
      this.socket_.close();
      this.socket_ = null;
    }
  }

  public SocketClient lastAcceptedClient() {
    return this.lastAcceptedClient_;
  }

  public ushort port() const {
    return this.port_;
  }

  package Socket socket() {
    return this.socket_;
  }
}

import std.stdio;

unittest {
  auto server = new SocketServer();
  scope(exit) { server.close(); }

  assert(server.accept());
  assert(server.port);
  SocketClient[] clients;
  clients ~= new SocketClient("127.0.0.1", server.port);
  clients ~= new SocketClient("127.0.0.1", server.port);
  clients ~= new SocketClient("127.0.0.1", server.port);
  scope(exit) {
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
  scope(exit) {
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

  assert(clients[0].send(cast(const(byte[]))"foo"));
  assert(clients[0].send(cast(const(byte[]))"bar"));
  assert(clients[0].send(cast(const(byte[]))"baz"));
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

  assert(clientsInServer[1].send(cast(const(byte[]))"FOO"));
  assert(clientsInServer[1].send(cast(const(byte[]))"BAR"));
  assert(clientsInServer[1].send(cast(const(byte[]))"BAZ"));
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
}

unittest {
  // send empty data
  auto server = new SocketServer();
  scope(exit) { server.close(); }

  auto client = new SocketClient("127.0.0.1", server.port);
  scope(exit) { server.close(); }

  SocketClient clientInServer;
  do {
    assert(server.accept());
    clientInServer = server.lastAcceptedClient;
  } while (!clientInServer);

  byte[] data;
  assert(client.send(data));
  client.close();
  assert(!client.send(data));
}

unittest {
  // send big data
  auto server = new SocketServer();
  scope(exit) { server.close(); }

  auto client = new SocketClient("127.0.0.1", server.port);
  scope(exit) { server.close(); }

  SocketClient clientInServer;
  do {
    assert(server.accept());
    clientInServer = server.lastAcceptedClient;
  } while (!clientInServer);

  byte[] sentData;
  sentData.length = 16777216;
  assert(client.send(sentData));
  
  byte[] receivedData;
  do {
    assert(clientInServer.receive);
    receivedData ~= clientInServer.lastReceivedData();
  } while (receivedData.length < sentData.length);
  assert(sentData.length == receivedData.length);
}
