module kaiko.storage.sessionprocessor;

import kaiko.storage.serversession;

version (unittest) {
  import kaiko.test.mockipcsession;
}

final class SessionProcessor(IPCSession_) {

  alias IPCSession_ IPCSession;

  public void process(in IPCSession[] ipcSessions) {
  }

}

unittest {
  // empty
  {
    auto processor = new SessionProcessor!MockIPCSession();
    MockIPCSession[] sessions;
    processor.process(sessions);
  }
}
