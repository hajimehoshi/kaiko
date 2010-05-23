module kaiko.ipc.socketclient;

import std.c.windows.winsock;
import std.socket;
import std.stdio;

class SocketClient {

  private Socket socket_;
  private byte[] lastReceivedData_;

  public this(string ip, ushort port) {
    this.socket_ = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    this.socket_.connect(new InternetAddress(ip, port));
  }

  public this(Socket socket) in {
    assert(socket);
  } body {
    this.socket_ = socket;
  }

  public void close() {
    if (this.socket_) {
      this.socket_.shutdown(SocketShutdown.BOTH);
      this.socket_.close();
      this.socket_ = null;
    }
  }

  public const(byte[]) lastReceivedData() const {
    return this.lastReceivedData_;
  }

  public bool receive() {
    if (!this.socket_) {
      return false;
    }
    this.socket_.blocking = false;
    byte[4096] buffer;
    immutable receivedLength = this.socket_.receive(buffer);
    switch (receivedLength) {
    case 0:
      this.lastReceivedData_.length = 0;
      return false;
    case Socket.ERROR:
      if (.WSAGetLastError() == .WSAEWOULDBLOCK) {
        this.lastReceivedData_.length = 0;
        return true;
      } else {
        throw new SocketException("Receving error", .WSAGetLastError());
      }
    default:
      this.lastReceivedData_ = buffer[0..receivedLength];
      return true;
    }
  }

  public bool send(const(byte[]) data) {
    if (!this.socket_) {
      return false;
    }
    if (!data.length) {
      return true;
    }
    this.socket_.blocking = false;
    immutable sentLength = this.socket_.send(data);
    switch (sentLength) {
    case 0:
      return false;
    case Socket.ERROR:
      if (.WSAGetLastError() == .WSAEWOULDBLOCK) {
        return true;
      } else {
        throw new SocketException("Sending error", .WSAGetLastError());
      }
    default:
      if (data.length != sentLength) {
        throw new SocketException("Sending error", .WSAGetLastError());
      }
      return true;
    }
  }

  package Socket socket() {
    return this.socket_;
  }
}
