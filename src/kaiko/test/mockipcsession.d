module kaiko.test.mockipcsession;

version (unittest) {

  final class MockIPCSession {

    private immutable(ubyte)[][] dataCollectionToSend_;
    public immutable(ubyte)[][] receivedDataCollection_ = [[]];
    public bool isClosed_;

    public void addDataToSend(in ubyte[] data) {
      this.dataCollectionToSend_ ~= data.idup;
    }

    public void close() {
      this.isClosed_ = true;
    }

    @property
    public immutable(ubyte)[] lastReceivedData() const {
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
      return true;
    }

  }

}

unittest {
  auto session = new MockIPCSession();
  session.receivedDataCollection_ ~= [1, 2, 3];
  assert([] == session.lastReceivedData);
  assert(session.receive());
  assert([1, 2, 3] == session.lastReceivedData);
}
