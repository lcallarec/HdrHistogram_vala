namespace HdrHistogram { 
    
    public class ZigZagEncoder {

        private ByteArrayWriter writer = new ByteArrayWriter(ByteOrder.LITTLE_ENDIAN);

        public ByteArray to_byte_array() {
            return writer.to_byte_array();
        }

        /**
         * Writes an int64 value to the given buffer in LEB128 ZigZag encoded format
         * @param buffer the buffer to write to
         * @param value  the value to write to the buffer
         */
        public void encode_int64(int64 value) {
            value = (value << 1) ^ (value >> 63);
            if (value >> 7 == 0) {
                writer.put_int8((int8) value);
            } else {
                writer.put_int8((int8) ((value & 0x7F) | 0x80));
                if (value >> 14 == 0) {
                    writer.put_int8((int8) (value >> 7));
                } else {
                    writer.put_int8((int8) (value >> 7 | 0x80));
                    if (value >> 21 == 0) {
                        writer.put_int8((int8) (value >> 14));
                    } else {
                        writer.put_int8((int8) (value >> 14 | 0x80));
                        if (value >> 28 == 0) {
                            writer.put_int8((int8) (value >> 21));
                        } else {
                            writer.put_int8((int8) (value >> 21 | 0x80));
                            if (value >> 35 == 0) {
                                writer.put_int8((int8) (value >> 28));
                            } else {
                                writer.put_int8((int8) (value >> 28 | 0x80));
                                if (value >> 42 == 0) {
                                    writer.put_int8((int8) (value >> 35));
                                } else {
                                    writer.put_int8((int8) (value >> 35 | 0x80));
                                    if (value >> 49 == 0) {
                                        writer.put_int8((int8) (value >> 42));
                                    } else {
                                        writer.put_int8((int8) (value >> 42 | 0x80));
                                        if (value >> 56 == 0) {
                                            writer.put_int8((int8) (value >> 49));
                                        } else {
                                            writer.put_int8((int8) (value >> 49 | 0x80));
                                            writer.put_int8((int8) (value >> 56));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}