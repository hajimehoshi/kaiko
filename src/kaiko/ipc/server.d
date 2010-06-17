module kaiko.ipc.server;

private import std.traits;

final class Server(SessionProcessor) {

  alias SessionProcessor.IPCSession IPCSession;
  alias IPCSession.TransportClient.Server TransportServer;
  private TransportServer transportServer_;
  private SessionProcessor sessionProcessor_;
  private bool[IPCSession] ipcSessions_;

  public this(TransportServer transportServer, SessionProcessor sessionProcessor) {
    this.transportServer_ = transportServer;
    this.sessionProcessor_ = sessionProcessor;
  }

  public void process() {
    this.transportServer_.accept();
    auto client = this.transportServer_.lastAcceptedClient;
    if (client) {
      auto ipcSession = new IPCSession(client);
      this.ipcSessions_[ipcSession] = true;
      this.sessionProcessor_.add(ipcSession);
    }
    // receiving
    foreach (ipcSession; this.ipcSessions_.keys) {
      if (!ipcSession.receive()) {
        this.sessionProcessor_.remove(ipcSession);
        ipcSession.close();
        this.ipcSessions_.remove(ipcSession);
      }
    }
    // processing
    this.sessionProcessor_.process();
    // sending
    foreach (ipcSession; this.ipcSessions_.keys) {
      if (!ipcSession.send()) {
        this.sessionProcessor_.remove(ipcSession);
        ipcSession.close();
        this.ipcSessions_.remove(ipcSession);
      }
    }
  }

}

unittest {
}
