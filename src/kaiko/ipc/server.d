module kaiko.ipc.server;

template Client(TransportServer) {
  alias typeof({TransportServer t; return t.lastAcceptedClient;}()) Client;
}

final class Server(TransportServer, SessionProcessor) {

  alias Client!TransportServer TransportClient;
  private TransportServer transportServer_;
  private SessionProcessor sessionProcessor_;

  public void process() {
    this.transportServer_.accept();
  }

}
