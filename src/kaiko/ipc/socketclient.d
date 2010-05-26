module kaiko.ipc.socketclient;

import std.c.windows.winsock;
import std.socket;

final class SocketClient {

  private Socket socket_;
  private immutable(ubyte)[] lastReceivedData_;
  private immutable(ubyte)[] dataToSend_;

  public this(in string ip, in ushort port) {
    this.socket_ = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    this.socket_.connect(new InternetAddress(ip, port));
  }

  public this(Socket socket) {
    assert(socket);
    this.socket_ = socket;
  }

  public void addDataToSend(in ubyte[] data) {
    this.dataToSend_ ~= data;
  }

  public void close() {
    if (this.socket_) {
      this.socket_.shutdown(SocketShutdown.BOTH);
      this.socket_.close();
      this.socket_ = null;
    }
  }

  @property
  public immutable(ubyte)[] lastReceivedData() {
    return this.lastReceivedData_;
  }

  public bool receive() {
    if (!this.socket_) {
      return false;
    }
    auto socketSet = new SocketSet(1);
    socketSet.add(this.socket_);
    switch (Socket.select(socketSet, null, null, 0)) {
    case 0:  // timeout
    case -1: // EINTR
      this.lastReceivedData_ = null;
      return true;
    default:
      break;
    }
    ubyte[4096] buffer;
    immutable receivedLength = this.socket_.receive(buffer);
    switch (receivedLength) {
    case 0:
      this.lastReceivedData_ = null;
      return false;
    case Socket.ERROR:
      throw new SocketException("Socket recv error", .WSAGetLastError());
    default:
      assert(receivedLength <= buffer.length);
      this.lastReceivedData_ = buffer[0..receivedLength].idup;
      return true;
    }
  }

  public bool send() {
    if (!this.socket_) {
      return false;
    }
    if (!this.dataToSend_.length) {
      return true;
    }
    auto socketSet = new SocketSet(1);
    socketSet.add(this.socket_);
    switch (Socket.select(null, socketSet, null, 0)) {
    case 0:  // timeout
    case -1: // EINTR
      return true;
    default:
      break;
    }
    immutable sentLength = this.socket_.send(this.dataToSend_);
    switch (sentLength) {
    case 0:
      return false;
    case Socket.ERROR:
      throw new SocketException("Socket send error", .WSAGetLastError());
    default:
      assert(sentLength <= this.dataToSend_.length);
      this.dataToSend_ = this.dataToSend_[sentLength..$];
      return true;
    }
  }

  @property
  package Socket socket() {
    return this.socket_;
  }

}
