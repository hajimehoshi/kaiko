module kaiko.ipc.server;

import std.traits;

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
      this.ipcSessions_[new IPCSession(client)] = true;
    }
    // receiving
    foreach (session; this.ipcSessions_.keys) {
      if (!session.receive()) {
        session.close();
        this.ipcSessions_.remove(session);
      }
    }
    // processing
    this.sessionProcessor_.process(this.ipcSessions_.keys);
    // sending
    foreach (session; this.ipcSessions_.keys) {
      if (!session.send()) {
        session.close();
        this.ipcSessions_.remove(session);
      }
    }
  }

}

unittest {
}
