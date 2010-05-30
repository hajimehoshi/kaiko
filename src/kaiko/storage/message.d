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
    foreach (i, member; this.tupleof) {
      static if (i == 0) {
        packer.pack(cast(int)member);
      } else {
        packer.pack(member);
      }
    }
  }

  public void mp_unpack(mp_Object object) {
    if (object.type != mp_Type.ARRAY) {
      throw new InvalidTypeException("mp_Object must be Array type");
    }
    foreach (i, member; this.tupleof) {
      static if (i == 0) {
        this.tupleof[i] = cast(typeof(member))(object.via.array[i].as!int);
      } else {
        this.tupleof[i] = object.via.array[i].as!(typeof(member));
      }
    }
  }

  public void deserialize(in ubyte[] bytes) {
    assert(0 < bytes.length);
    this.mp_unpack(unpack(bytes));
  }

  public ubyte[] serialize() {
    return pack(this);
  }

}

unittest {
  {
    Message message = {
      MessageType.Unsubcribe,
    }, result;
    result.deserialize(message.serialize());
    assert(message.type == result.type);
  }
}
