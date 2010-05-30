module kaiko.storage.sessionprocessor;

import kaiko.storage.message;

version (unittest) {
  import kaiko.test.mocksession;
}

final class SessionProcessor(Session_) {

  alias Session_ Session;

  public void process(in Session[] sessions) {
    foreach (session; sessions) {
      //auto data = cast(string)(session.lastReceivedData);
      
    }
  }

}

unittest {
  // empty
  {
    auto processor = new SessionProcessor!MockSession();
    MockSession[] sessions;
    processor.process(sessions);
  }
}
