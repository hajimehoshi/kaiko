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
  private byte[][] dataCollectionToSend_;
  private byte[] lastReceivedData_;
  private ReceivingState receivingState_ = ReceivingState.Init;
  private int restLengthToRead_;
  private byte[] bufferedData_;

  public this(TransportClient transportClient) {
    this.transportClient_ = transportClient;
  }
 
  public void addDataToSend(const(byte[]) data) {
    this.dataCollectionToSend_ ~= data.dup;
  }

  public void close() {
    this.transportClient_.close();
    this.isActive_ = false;
    this.dataCollectionToSend_ = null;
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
      final switch (this.receivingState_) {
      case ReceivingState.Init:
        assert(0 < this.bufferedData_.length);
        assert(!this.restLengthToRead_);
        if (this.bufferedData_[0] == cast(byte)0x80) {
          this.receivingState_ = ReceivingState.Length;
        } else {
          goto Failed;
        }
        break;
      case ReceivingState.Length:
        assert(0 < this.restLengthToRead_);
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
          assert(readBytesNum <= this.bufferedData_.length);
          this.restLengthToRead_ = length;
          this.bufferedData_ = this.bufferedData_[readBytesNum..$];
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
        this.lastReceivedData_ = this.bufferedData_[0..this.restLengthToRead_];
        this.bufferedData_ = this.bufferedData_[this.restLengthToRead_..$];
        this.receivingState_ = ReceivingState.Init;
        this.restLengthToRead_ = 0;
        break;
      case ReceivingState.Terminated:
        assert(0);
      }
    }
    return true;
  Failed:
    this.close();
    return false;
  }

  public bool send() {
    if (!this.isActive_) {
      return false;
    }
    foreach (data; this.dataCollectionToSend_) {
      if (!data.length) {
        continue;
      }
      const lengthPart = lengthToBytes(data.length);
      this.transportClient_.addDataToSend(cast(byte[])[0x80]);
      this.transportClient_.addDataToSend(lengthPart);
      this.transportClient_.addDataToSend(data);
    }
    this.dataCollectionToSend_ = null;
    if (!this.transportClient_.send()) {
      this.close();
      return false;
    }
    return true;
  }

}

unittest {
  class MockTransportClient {
    private byte[] lastReceivedData_;
    public void addDataToSend(const(byte[]) data) {
    }
    public void close() {
    }
    @property
    public const(byte[]) lastReceivedData() {
      return this.lastReceivedData_;
    }
    public bool receive() {
      return true;
    }
    public bool send() {  
      return true;
    }
  }
  auto simpleSession = new SimpleSession!MockTransportClient(new MockTransportClient);
}

private int bytesToLength(const(byte[]) bytes, out int readBytesNum) {
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
