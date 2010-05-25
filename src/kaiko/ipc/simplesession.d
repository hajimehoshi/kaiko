module kaiko.ipc.simplesession;

class SimpleSession(TransportClient) {

  private enum ReceivingState {
    Init,
    Length,
    Data,
    Terminated,
  }

  private TransportClient transportClient_;
  private bool isActive_ = true;
  private byte[] lastReceivedData_;
  private ReceivingState receivingState_ = ReceivingState.Init;
  private int restLengthToRead_;
  private byte[] bufferedData_;

  public this(TransportClient transportClient) {
    this.transportClient_ = transportClient;
  }
 
  public void addDataToSend(in byte[] data) {
    if (!data) {
      // empty
      // TODO: logging
      return;
    }
    this.transportClient_.addDataToSend(cast(byte[])[0x80]);
    this.transportClient_.addDataToSend(lengthToBytes(data.length));
    this.transportClient_.addDataToSend(data);      
  }

  public void close() {
    this.transportClient_.close();
    this.isActive_ = false;
    this.lastReceivedData_ = null;
    this.receivingState_ = ReceivingState.Terminated;
    this.restLengthToRead_ = 0;
    this.bufferedData_ = null;
  }

  @property
  public const(byte[]) lastReceivedData() {
    return this.lastReceivedData_;
  }

  public bool receive() {
    if (!this.isActive_) {
      return false;
    }
    if (!this.transportClient_.receive()) {
      this.close();
      return false;
    }
    this.bufferedData_ ~= this.transportClient_.lastReceivedData;
    for (;;) {
      if (!this.bufferedData_.length) {
        this.lastReceivedData_ = null;
        return true;
      }
      assert(0 < this.bufferedData_.length);
      final switch (this.receivingState_) {
      case ReceivingState.Init:
        assert(!this.restLengthToRead_);
        if (this.bufferedData_[0] == cast(byte)0x80) {
          this.bufferedData_ = this.bufferedData_[1..$].dup;
          this.receivingState_ = ReceivingState.Length;
        } else {
          goto Failed;
        }
        break;
      case ReceivingState.Length:
        assert(!this.restLengthToRead_);
        {
          int length;
          int readBytesNum;
          try {
            length = bytesToLength(this.bufferedData_, readBytesNum);
          } catch (Exception) {
            // TODO: logging
            goto Failed;
          }
          if (!readBytesNum) {
            return true;
          }
          assert(0 <= length);
          assert(0 <= readBytesNum);
          assert(readBytesNum <= this.bufferedData_.length);
          this.restLengthToRead_ = length;
          this.bufferedData_ = this.bufferedData_[readBytesNum..$].dup;
          if (length) {
            this.receivingState_ = ReceivingState.Data;
          } else {
            // empty size
            // TODO: logging
            this.receivingState_ = ReceivingState.Init;
          }
        }
        break;
      case ReceivingState.Data:
        assert(0 < this.bufferedData_.length);
        assert(0 < this.restLengthToRead_);
        if (this.bufferedData_.length < this.restLengthToRead_) {
          this.lastReceivedData_ = null;
          return true;
        }
        this.lastReceivedData_ = this.bufferedData_[0..this.restLengthToRead_].dup;
        this.bufferedData_ = this.bufferedData_[this.restLengthToRead_..$].dup;
        this.receivingState_ = ReceivingState.Init;
        this.restLengthToRead_ = 0;
        return true;
      case ReceivingState.Terminated:
        assert(0);
      }
    }
  Failed:
    this.close();
    return false;
  }

  public bool send() {
    if (!this.isActive_) {
      return false;
    }
    if (!this.transportClient_.send()) {
      this.close();
      return false;
    }
    return true;
  }

}

unittest {
  class MockTransportClient {
    private byte[] dataToSend_;
    public byte[] sentData_;
    public byte[][] receivedDataCollection_ = [[]];
    public bool isClosed_;
    public void addDataToSend(in byte[] data) {
      this.dataToSend_ ~= data;
    }
    public void close() {
      this.isClosed_ = true;
    }
    @property
    public const(byte[]) lastReceivedData() {
      if (this.receivedDataCollection_) {
        return this.receivedDataCollection_[0];
      } else {
        return null;
      }
    }
    public bool receive() {
      if (this.isClosed_) {
        return false;
      }
      if (this.receivedDataCollection_) {
        this.receivedDataCollection_ = this.receivedDataCollection_[1..$].dup;
      }
      return true;
    }
    public bool send() {
      if (this.isClosed_) {
        return false;
      }
      this.sentData_ = this.dataToSend_.dup;
      return true;
    }
  }
  // send
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    session.addDataToSend(cast(byte[])[]);
    assert(session.send());
    assert(cast(byte[])[] == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    byte[] data;
    data.length = 127;
    data[0..$] = cast(byte)'a';
    session.addDataToSend(data);
    assert(session.send());
    assert(cast(byte[])[0x80, 0x7f] ~ data == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    byte[] data;
    data.length = 128;
    data[0..$] = cast(byte)'a';
    session.addDataToSend(data);
    assert(session.send());
    assert(cast(byte[])[0x80, 0x81, 0x00] ~ data == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    byte[] data;
    data.length = 129;
    data[0..$] = cast(byte)'a';
    session.addDataToSend(data);
    assert(session.send());
    assert(cast(byte[])[0x80, 0x81, 0x01] ~ data == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    byte[] data;
    data.length = 200;
    data[0..$] = cast(byte)'a';
    session.addDataToSend(data);
    assert(session.send());
    assert(cast(byte[])[0x80, 0x81, 0x48] ~ data == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    byte[] data;
    data.length = 314159;
    data[0..$] = cast(byte)'a';
    session.addDataToSend(data);
    assert(session.send());
    assert(cast(byte[])[0x80, 0x93, 0x96, 0x2f] ~ data == transportClient.sentData_);
  }
  // send continuously
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    session.addDataToSend(cast(byte[])"foo");
    session.addDataToSend(cast(byte[])"barbaz");
    assert(session.send());
    assert(cast(byte[])[0x80, 0x03, 'f', 'o', 'o', 0x80, 0x06, 'b', 'a', 'r', 'b', 'a', 'z'] ==
           transportClient.sentData_);
  }
  // receive
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable header = cast(byte[])[0x80, 0x7f];
    byte[] data;
    data.length = 127;
    data[0..$] = cast(byte)'a';
    transportClient.receivedDataCollection_ ~= header ~ data;
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable header = cast(byte[])[0x80, 0x81, 0x00];
    byte[] data;
    data.length = 128;
    data[0..$] = cast(byte)'a';
    transportClient.receivedDataCollection_ ~= header ~ data;
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable header = cast(byte[])[0x80, 0x81, 0x01];
    byte[] data;
    data.length = 129;
    data[0..$] = cast(byte)'a';
    transportClient.receivedDataCollection_ ~= header ~ data;
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable header = cast(byte[])[0x80, 0x81, 0x48];
    byte[] data;
    data.length = 200;
    data[0..$] = cast(byte)'a';
    transportClient.receivedDataCollection_ ~= header ~ data;
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable header = cast(byte[])[0x80, 0x93, 0x96, 0x2f];
    byte[] data;
    data.length = 314159;
    data[0..$] = cast(byte)'a';
    transportClient.receivedDataCollection_ ~= header ~ data;
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  // receive continuously
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~=
      cast(byte[])[0x80, 0x03, 'f', 'o', 'o', 0x80, 0x06, 'b', 'a', 'r', 'b', 'a', 'z'];
    assert(session.receive());
    assert(cast(byte[])"foo" == session.lastReceivedData);
    assert(session.receive());
    assert(cast(byte[])"barbaz" == session.lastReceivedData);
    assert(session.receive());
    assert([] == session.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~=
      [cast(byte[])[0x80, 0x03, 'f'],
       [],
       cast(byte[])['o', 'o', 0x80],
       [],
       [],
       cast(byte[])[0x06, 'b', 'a', 'r', 'b', 'a', 'z']];
    do {
      assert(session.receive());
    } while (!session.lastReceivedData.length);
    assert(cast(byte[])"foo" == session.lastReceivedData);
    do {
      assert(session.receive());
    } while (!session.lastReceivedData.length);
    assert(cast(byte[])"barbaz" == session.lastReceivedData);
    assert(session.receive());
    assert([] == session.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    auto header = cast(byte[])[0x80, 0x99, 0x80, 0x00];
    byte[] data;
    data.length = 4096 * 100;
    data[0..$] = cast(byte)'a';
    transportClient.receivedDataCollection_ ~= header;
    for (int i = 0; i < 100; i++) {
      byte[] dataPacket;
      dataPacket.length = 4096;
      dataPacket[0..$] = cast(byte)'a';
      transportClient.receivedDataCollection_ ~= dataPacket;
    }
    do {
      assert(session.receive());
    } while (!session.lastReceivedData.length);
    assert(data == session.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  // receive invalid bytes
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= cast(byte[])[0xff];
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= cast(byte[])[0x80, 0x03, 'f', 'o', 'o', 0xff];
    assert(session.receive());
    assert(cast(byte[])"foo" == session.lastReceivedData);
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= cast(byte[])[0x80, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff];
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
  {
    // empty data
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= cast(byte[])[0x80, 0x00, 0x80, 0x03, 'f', 'o', 'o'];
    assert(session.receive());
    assert(cast(byte[])"foo" == session.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    // empty data (redundant bytes)
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= cast(byte[])[0x80, 0x80, 0x80, 0x00, 0x80, 0x03, 'f', 'o', 'o'];
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
}

private int bytesToLength(in byte[] bytes, out int readBytesNum) {
  int length = 0;
  readBytesNum = 0;
  foreach (b; bytes) {
    readBytesNum++;
    length <<= 7;
    length += b & 0x7f;
    if (length == 0 && b == cast(byte)0x80) {
      throw new Exception("Redundant bytes");
    }
    if (length < 0) {
      throw new Exception("Too big length");
    }
    if ((b & 0x80) == 0) {
      return length;
    }
  }
  readBytesNum = 0;
  return 0;
}

unittest {
  {
    int readBytesNum;
    immutable length = bytesToLength([], readBytesNum);
    assert(0 == length);
    assert(0 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength(cast(byte[])[0x03], readBytesNum);
    assert(3 == length);
    assert(1 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength(cast(byte[])[0x7f], readBytesNum);
    assert(127 == length);
    assert(1 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength(cast(byte[])[0x81, 0x00], readBytesNum);
    assert(128 == length);
    assert(2 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength(cast(byte[])[0x81, 0x01], readBytesNum);
    assert(129 == length);
    assert(2 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength(cast(byte[])[0x81, 0x48], readBytesNum);
    assert(200 == length);
    assert(2 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength(cast(byte[])[0x93, 0x96, 0x2f], readBytesNum);
    assert(314159 == length);
    assert(3 == readBytesNum);
  }
  {
    try {
      int readBytesNum;
      bytesToLength(cast(byte[])[0xff, 0xff, 0xff, 0xff, 0xff], readBytesNum);
      assert(0);
    } catch (Exception) {
    }
  }
  {
    try {
      // redundant bytes
      int readBytesNum;
      bytesToLength(cast(byte[])[0x80, 0x01], readBytesNum);
      assert(0);
    } catch (Exception) {
    }
  }
}

private const(byte[]) lengthToBytes(int length) {
  byte[] bytes = [length & 0x7f];
  for (;;) {
    length >>= 7;
    if (!length) {
      break;
    }
    bytes = (0x80 | (length & 0x7f)) ~ bytes;
  }
  return bytes;
}

import std.stdio;
 
unittest {
  assert(cast(byte[])[0x03] == lengthToBytes(3));
  assert(cast(byte[])[0x7f] == lengthToBytes(127));
  assert(cast(byte[])[0x81, 0x00] == cast(byte[])lengthToBytes(128));
  assert(cast(byte[])[0x81, 0x01] == cast(byte[])lengthToBytes(129));
  assert(cast(byte[])[0x81, 0x48] == cast(byte[])lengthToBytes(200));
  assert(cast(byte[])[0x93, 0x96, 0x2f] == cast(byte[])lengthToBytes(314159));
}
