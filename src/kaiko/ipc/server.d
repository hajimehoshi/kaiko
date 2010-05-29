module kaiko.ipc.server;

import std.traits;

final class Server(SessionProcessor) {

  alias SessionProcessor.Session Session;
  alias Session.TransportClient.Server TransportServer;
  private TransportServer transportServer_;
  private SessionProcessor sessionProcessor_;
  private bool[Session] sessions_;

  public this(TransportServer transportServer, SessionProcessor sessionProcessor) {
    this.transportServer_ = transportServer;
    this.sessionProcessor_ = sessionProcessor;
  }

  public void process() {
    this.transportServer_.accept();
    auto client = this.transportServer_.lastAcceptedClient;
    if (client) {
      this.sessions_[new Session(client)] = true;
    }
    // receiving
    foreach (session; this.sessions_.keys) {
      if (!session.receive()) {
        session.close();
        this.sessions_.remove(session);
      }
    }
    // processing
    this.sessionProcessor_.process(this.sessions_.keys);
    // sending
    foreach (session; this.sessions_.keys) {
      if (!session.send()) {
        session.close();
        this.sessions_.remove(session);
      }
    }
  }

}

unittest {
}
