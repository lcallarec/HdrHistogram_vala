namespace HdrHistogram.ZigZag { 
    
    public class Encoder {

        private ByteArrayWriter writer = new ByteArrayWriter(ByteOrder.LITTLE_ENDIAN);

        public ByteArray to_byte_array() {
            return writer.to_byte_array();
        }

        /**
         * Writes an int64 value to the given buffer in LEB128 ZigZag encoded format
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

    public class Decoder {
        
        private ByteArrayReader reader;

        public Decoder(ByteArray buffer) {
            reader = new ByteArrayReader(buffer, ByteOrder.LITTLE_ENDIAN);
        }

        public Decoder.with_reader(ByteArrayReader reader) {
            this.reader = reader;
        }

        /**
         * Read an LEB128-64b9B ZigZag encoded int64 value from the given buffer
         * @return the value read from the buffer
         */
        public int64 decode_int64() {
            int64 v = reader.read_int8();
            int64 value = v & 0x7F;
            if ((v & 0x80) != 0) {
                v = reader.read_int8();
                value |= (v & 0x7F) << 7;
                if ((v & 0x80) != 0) {
                    v = reader.read_int8();
                    value |= (v & 0x7F) << 14;
                    if ((v & 0x80) != 0) {
                        v = reader.read_int8();
                        value |= (v & 0x7F) << 21;
                        if ((v & 0x80) != 0) {
                            v = reader.read_int8();
                            value |= (v & 0x7F) << 28;
                            if ((v & 0x80) != 0) {
                                v = reader.read_int8();
                                value |= (v & 0x7F) << 35;
                                if ((v & 0x80) != 0) {
                                    v = reader.read_int8();
                                    value |= (v & 0x7F) << 42;
                                    if ((v & 0x80) != 0) {
                                        v = reader.read_int8();
                                        value |= (v & 0x7F) << 49;
                                        if ((v & 0x80) != 0) {
                                            v = reader.read_int8();
                                            value |= v << 56;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            value = (value >> 1) ^ (-(value & 1));
            return value;
        }   
    }
}