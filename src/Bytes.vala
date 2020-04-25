namespace HdrHistogram { 

    //  public class ByteBuffer {
    //      private ByteArray buffer;
        
    //      public ByteBuffer(int size) {
    //          buffer = new ByteArray.sized(size);
    //      }
        
    //      public void appendInt(int value) {

    //          append(bytes);
    //      }

    //      public void appendInt64(int64 value) {
    //          int64 v = value.to_big_endian();
    //          uint8[] bytes = (uint8[])&v;
    //          append(bytes);
    //      }

    //      public uint8[] get_data() {
    //          return buffer.data;
    //      }

    //      public uint get_length() {
    //          return buffer.len;
    //      }

    //      private void append(uint8[] bytes) {
    //          buffer.append(bytes);
    //      }
    //  }

    Bytes int8_to_bytes(int8 value) {
        int8 v = value;
        uint8[] bytes = (uint8[])&v;
        return new Bytes.take(bytes);
    }

    Bytes int_to_bytes(int value) {
        int v = value.to_big_endian();
        uint8[] bytes = (uint8[])&v;
        return new Bytes.take(bytes);
    }

    Bytes int64_to_bytes(int64 value) {
        int64 v = value.to_big_endian();
        uint8[] bytes = (uint8[])&v;
        return new Bytes.take(bytes);
    }

    Bytes double_to_bytes(double value) {
        double v = value;
        uint8[] bytes = (uint8[])&v;
        return new Bytes.take(bytes);
    }
}