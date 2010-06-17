module kaiko.storage.sessionprocessor;

private import kaiko.storage.serversession;
private import kaiko.storage.session;

version (unittest) {
  import kaiko.test.mockipcsession;
}

final class SessionProcessor(IPCSession_) {

  alias IPCSession_ IPCSession;
  private Session[IPCSession] sessions_;

  public void add(IPCSession ipcSession) {
    this.sessions_[ipcSession] = new Session();
  }

  public void process() {
    foreach (ipcSession, serverSession; this.sessions_) {
      
    }
  }

  public void remove(IPCSession ipcSession) {
    if (ipcSession in this.sessions_) {
      this.sessions_[ipcSession].close();
      this.sessions_.remove(ipcSession);
    } else {
      // logging
    }
  }

}

unittest {
  // empty
  {
    auto processor = new SessionProcessor!MockIPCSession();
    processor.process();
  }
}
