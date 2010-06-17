module kaiko.ipc.simplesession;

version (unittest) {
  private import kaiko.test.mocktransportclient;
}

final class SimpleSession(TransportClient_) {

  alias TransportClient_ TransportClient;

  private enum ReceivingState {
    INITIAL,
    LENGTH,
    DATA,
    TERMINATED,
  }

  private TransportClient transportClient_;
  private bool isActive_ = true;
  private immutable(ubyte)[][] lastReceivedDataCollection_;
  private ReceivingState receivingState_ = ReceivingState.INITIAL;
  private int nextDataLength_;
  private immutable(ubyte)[] bufferedData_;

  public this(TransportClient transportClient) {
    this.transportClient_ = transportClient;
  }
 
  public void addDataToSend(in ubyte[] data) {
    if (!data) {
      // empty
      // TODO: logging
      return;
    }
    this.transportClient_.addDataToSend([0x80]);
    this.transportClient_.addDataToSend(lengthToBytes(data.length));
    this.transportClient_.addDataToSend(data);      
  }

  public void close() {
    this.transportClient_.close();
    this.isActive_ = false;
    this.lastReceivedDataCollection_ = null;
    this.receivingState_ = ReceivingState.TERMINATED;
    this.nextDataLength_ = 0;
    this.bufferedData_ = null;
  }

  @property
  public immutable(ubyte)[] lastReceivedData() const {
    if (this.lastReceivedDataCollection_.length) {
      return this.lastReceivedDataCollection_[0];
    } else {
      return null;
    }
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
    return this.moveNext();
  }

  private bool moveNext() {
    if (this.lastReceivedDataCollection_.length) {
      this.lastReceivedDataCollection_ = this.lastReceivedDataCollection_[1..$];
    }
    for (;;) {
      final switch (this.receivingState_) {
      case ReceivingState.INITIAL:
        if (!this.bufferedData_.length) {
          return true;
        }
        assert(0 < this.bufferedData_.length);
        assert(!this.nextDataLength_);
        if (this.bufferedData_[0] == 0x80) {
          this.bufferedData_ = this.bufferedData_[1..$];
          this.receivingState_ = ReceivingState.LENGTH;
        } else {
          this.receivingState_ = ReceivingState.TERMINATED;
        }
        break;
      case ReceivingState.LENGTH:
        if (!this.bufferedData_.length) {
          return true;
        }
        assert(0 < this.bufferedData_.length);
        assert(!this.nextDataLength_);
        int length, readBytesNum;
        try {
          length = bytesToLength(this.bufferedData_, readBytesNum);
        } catch (Exception) {
          // TODO: logging
          this.receivingState_ = ReceivingState.TERMINATED;
          break;
        }
        assert(0 <= length);
        assert(0 <= readBytesNum);
        assert(readBytesNum <= this.bufferedData_.length);
        if (readBytesNum) {
          this.bufferedData_ = this.bufferedData_[readBytesNum..$];
          if (length) {
            this.nextDataLength_ = length;
            this.receivingState_ = ReceivingState.DATA;
          } else {
            // empty size
            // TODO: logging
            this.receivingState_ = ReceivingState.INITIAL;
          }
        }
        break;
      case ReceivingState.DATA:
        if (!this.bufferedData_.length) {
          return true;
        }
        assert(0 < this.bufferedData_.length);
        assert(0 < this.nextDataLength_);
        if (this.bufferedData_.length < this.nextDataLength_) {
          return true;
        }
        this.lastReceivedDataCollection_ ~= this.bufferedData_[0..this.nextDataLength_];
        this.bufferedData_ = this.bufferedData_[this.nextDataLength_..$];
        this.receivingState_ = ReceivingState.INITIAL;
        this.nextDataLength_ = 0;
        break;
      case ReceivingState.TERMINATED:
        if (this.lastReceivedDataCollection_.length) {
          return true;
        } else {
          this.close();
          return false;
        }
      }
    }
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
  // send
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    session.addDataToSend([]);
    assert(session.send());
    assert([] == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    auto data = new ubyte[127];
    data[0..$] = 'a';
    session.addDataToSend(data);
    assert(session.send());
    immutable(ubyte)[] header = [0x80, 0x7f];
    assert((header ~ data) == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    auto data = new ubyte[128];
    data[0..$] = 'a';
    session.addDataToSend(data);
    assert(session.send());
    immutable(ubyte)[] header = [0x80, 0x81, 0x00];
    assert((header ~ data) == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    auto data = new ubyte[129];
    data[0..$] = 'a';
    session.addDataToSend(data);
    assert(session.send());
    immutable(ubyte)[] header = [0x80, 0x81, 0x01];
    assert((header ~ data) == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    auto data = new ubyte[200];
    data[0..$] = 'a';
    session.addDataToSend(data);
    assert(session.send());
    immutable(ubyte)[] header = [0x80, 0x81, 0x48];
    assert((header ~ data) == transportClient.sentData_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    auto data = new ubyte[314159];
    data[0..$] = 'a';
    session.addDataToSend(data);
    assert(session.send());
    immutable(ubyte)[] header = [0x80, 0x93, 0x96, 0x2f];
    assert((header ~ data) == transportClient.sentData_);
  }
  // send continuously
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    session.addDataToSend(['f', 'o', 'o']);
    session.addDataToSend(['b', 'a', 'r', 'b', 'a', 'z']);
    assert(session.send());
    assert([0x80, 0x03, 'f', 'o', 'o', 0x80, 0x06, 'b', 'a', 'r', 'b', 'a', 'z'] ==
           transportClient.sentData_);
  }
  // receive
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable(ubyte)[] header = [0x80, 0x7f];
    auto data = new ubyte[127];
    data[0..$] = 'a';
    transportClient.receivedDataCollection_ ~= (header ~ data.idup);
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable(ubyte)[] header = [0x80, 0x81, 0x00];
    auto data = new ubyte[128];
    data[0..$] = 'a';
    transportClient.receivedDataCollection_ ~= (header ~ data.idup);
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable(ubyte)[] header = [0x80, 0x81, 0x01];
    auto data = new ubyte[129];
    data[0..$] = 'a';
    transportClient.receivedDataCollection_ ~= (header ~ data.idup);
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable(ubyte)[] header = [0x80, 0x81, 0x48];
    auto data = new ubyte[200];
    data[0..$] = 'a';
    transportClient.receivedDataCollection_ ~= (header ~ data.idup);
    assert(session.receive());
    assert(data == session.lastReceivedData);
    assert(header ~ data == transportClient.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable(ubyte)[] header = [0x80, 0x93, 0x96, 0x2f];
    auto data = new ubyte[314159];
    data[0..$] = 'a';
    transportClient.receivedDataCollection_ ~= (header ~ data.idup);
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
      [0x80, 0x03, 'f', 'o', 'o', 0x80, 0x06, 'b', 'a', 'r', 'b', 'a', 'z'];
    assert(session.receive());
    assert("foo" == session.lastReceivedData);
    assert(session.receive());
    assert("barbaz" == session.lastReceivedData);
    assert(session.receive());
    assert([] == session.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~=
      [[0x80, 0x03, 'f'],
       [],
       ['o', 'o', 0x80],
       [],
       [],
       [0x06, 'b', 'a', 'r', 'b', 'a', 'z'],
       [],
       [0x80, 0x03],
       [cast(ubyte)'q', 'u', 'x']];
    do {
      assert(session.receive());
    } while (!session.lastReceivedData.length);
    assert("foo" == session.lastReceivedData);
    do {
      assert(session.receive());
    } while (!session.lastReceivedData.length);
    assert("barbaz" == session.lastReceivedData);
    do {
      assert(session.receive());
    } while (!session.lastReceivedData.length);
    assert("qux" == session.lastReceivedData);
    assert(session.receive());
    assert([] == session.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    immutable(ubyte)[] header = [0x80, 0x99, 0x80, 0x00];
    auto data = new ubyte[4096 * 100];
    data[0..$] = 'a';
    transportClient.receivedDataCollection_ ~= header;
    foreach (i; 0..100) {
      auto dataPacket = new ubyte[4096];
      dataPacket[0..$] = 'a';
      transportClient.receivedDataCollection_ ~= dataPacket.idup;
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
    transportClient.receivedDataCollection_ ~= [0xff];
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= [0x80, 0x03, 'f', 'o', 'o', 0xff];
    assert(session.receive());
    assert("foo" == session.lastReceivedData);
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
  {
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= [0x80, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff];
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
  {
    // empty data
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= [0x80, 0x00, 0x80, 0x03, 'f', 'o', 'o'];
    assert(session.receive());
    assert("foo" == session.lastReceivedData);
    assert(!transportClient.isClosed_);
  }
  {
    // empty data (redundant bytes)
    auto transportClient = new MockTransportClient;
    auto session = new SimpleSession!MockTransportClient(transportClient);
    transportClient.receivedDataCollection_ ~= [0x80, 0x80, 0x80, 0x00, 0x80, 0x03, 'f', 'o', 'o'];
    assert(!session.receive());
    assert([] == session.lastReceivedData);
    assert(transportClient.isClosed_);
  }
}

private int bytesToLength(in ubyte[] bytes, out int readBytesNum) {
  int length = 0;
  readBytesNum = 0;
  foreach (b; bytes) {
    readBytesNum++;
    length <<= 7;
    length += b & 0x7f;
    if (length == 0 && b == 0x80) {
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
    immutable length = bytesToLength([0x03], readBytesNum);
    assert(3 == length);
    assert(1 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength([0x7f], readBytesNum);
    assert(127 == length);
    assert(1 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength([0x81, 0x00], readBytesNum);
    assert(128 == length);
    assert(2 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength([0x81, 0x01], readBytesNum);
    assert(129 == length);
    assert(2 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength([0x81, 0x48], readBytesNum);
    assert(200 == length);
    assert(2 == readBytesNum);
  }
  {
    int readBytesNum;
    immutable length = bytesToLength([0x93, 0x96, 0x2f], readBytesNum);
    assert(314159 == length);
    assert(3 == readBytesNum);
  }
  {
    try {
      int readBytesNum;
      bytesToLength([0xff, 0xff, 0xff, 0xff, 0xff], readBytesNum);
      assert(0);
    } catch (Exception) {
    }
  }
  {
    try {
      // redundant bytes
      int readBytesNum;
      bytesToLength([0x80, 0x01], readBytesNum);
      assert(0);
    } catch (Exception) {
    }
  }
}

private immutable(ubyte)[] lengthToBytes(int length)  {
  immutable(ubyte)[] bytes = [length & 0x7f];
  for (;;) {
    length >>= 7;
    if (!length) {
      break;
    }
    bytes = (0x80 | (length & 0x7f)) ~ bytes;
  }
  return bytes;
}

unittest {
  assert([0x03] == lengthToBytes(3));
  assert([0x7f] == lengthToBytes(127));
  assert([0x81, 0x00] == lengthToBytes(128));
  assert([0x81, 0x01] == lengthToBytes(129));
  assert([0x81, 0x48] == lengthToBytes(200));
  assert([0x93, 0x96, 0x2f] == lengthToBytes(314159));
}
