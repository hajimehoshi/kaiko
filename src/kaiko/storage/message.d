module kaiko.storage.message;

import msgpack.msgpack;

enum MessageType {
  Subcribe,
  Unsubcribe,
  Create,
  Read,
  Update,
  Delete,
}

import std.stdio;

struct Message {
  MessageType type;
  
  //mixin MessagePackable;

  public void mp_pack(Packer)(ref Packer packer) const {
    packer.packArray(this.tupleof.length);
    packer.pack(cast(int)this.type);
  }

  public void mp_unpack(mp_Object object) {
    if (object.type != mp_Type.ARRAY) {
      throw new InvalidTypeException("mp_Object must be Array type");
    }
    this.type = cast(MessageType)(object.via.array[0].as!int);
  }

  public void deserialize(in ubyte[] bytes) {
    assert(0 < bytes.length);
    this.mp_unpack(unpack(bytes));
  }

  public immutable(ubyte)[] serialize() {
    return pack(this).idup;
  }

}

unittest {
  {
    Message message = {
      MessageType.Subcribe,
    }, result;
    result.deserialize(message.serialize());
    assert(MessageType.Subcribe == result.type);
  }
  {
    Message message = {
      MessageType.Unsubcribe,
    }, result;
    result.deserialize(message.serialize());
    assert(MessageType.Unsubcribe == result.type);
  }
}
