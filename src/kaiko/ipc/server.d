module kaiko.ipc.server;

template Client(TransportServer) {
  alias typeof({return (new TransportServer()).lastAcceptedClient;}()) Client;
}

final class Server(TransportServer, SessionProcessor) {

  private TransportServer transportServer_;
  private SessionProcessor sessionProcessor_;

  public void Process() {
    this.transportServer_.accept();
  }

}