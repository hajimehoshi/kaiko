module kaiko.test.mocktransportclient;

version (unittest) {

  final class MockTransportClient {

    private immutable(ubyte)[] dataToSend_;
    public immutable(ubyte)[] sentData_;
    public immutable(ubyte)[][] receivedDataCollection_ = [[]];
    public bool isClosed_;

    public void addDataToSend(in ubyte[] data) {
      this.dataToSend_ ~= data;
    }

    public void close() {
      this.isClosed_ = true;
    }

    @property
    public immutable(ubyte)[] lastReceivedData() {
      if (this.receivedDataCollection_.length) {
        return this.receivedDataCollection_[0];
      } else {
        return null;
      }
    }

    public bool receive() {
      if (this.isClosed_) {
        return false;
      }
      if (this.receivedDataCollection_.length) {
        this.receivedDataCollection_ = this.receivedDataCollection_[1..$];
      }
      return true;
    }

    public bool send() {
      if (this.isClosed_) {
        return false;
      }
      this.sentData_ = this.dataToSend_;
      return true;
    }

  }

}

unittest {
  auto transportClient = new MockTransportClient;
  transportClient.receivedDataCollection_ ~= [1, 2, 3];
  assert([] == transportClient.lastReceivedData);
  assert(transportClient.receive());
  assert([1, 2, 3] == transportClient.lastReceivedData);
}
