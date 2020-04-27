namespace HdrHistogram { 
    
    public class ZigZagEncoder {

        private ByteArray buffer;
        private BytesConverter converter = new BytesConverter(ByteOrder.LITTLE_ENDIAN);

        public ZigZagEncoder(ByteArray buffer) {
            this.buffer = buffer;
        }

        /**
         * Writes an int64 value to the given buffer in LEB128 ZigZag encoded format
         * @param buffer the buffer to write to
         * @param value  the value to write to the buffer
         */
        public void encode_int64(int64 value) {
            value = (value << 1) ^ (value >> 63);
            if (value >> 7 == 0) {
                buffer.append(converter.int8_to_bytes((int8) value).get_data());
            } else {
                buffer.append(converter.int8_to_bytes((int8) ((value & 0x7F) | 0x80)).get_data());
                if (value >> 14 == 0) {
                    buffer.append(converter.int8_to_bytes((int8) (value >> 7)).get_data());
                } else {
                    buffer.append(converter.int8_to_bytes((int8) (value >> 7 | 0x80)).get_data());
                    if (value >> 21 == 0) {
                        buffer.append(converter.int8_to_bytes((int8) (value >> 14)).get_data());
                    } else {
                        buffer.append(converter.int8_to_bytes((int8) (value >> 14 | 0x80)).get_data());
                        if (value >> 28 == 0) {
                            buffer.append(converter.int8_to_bytes((int8) (value >> 21)).get_data());
                        } else {
                            buffer.append(converter.int8_to_bytes((int8) (value >> 21 | 0x80)).get_data());
                            if (value >> 35 == 0) {
                                buffer.append(converter.int8_to_bytes((int8) (value >> 28)).get_data());
                            } else {
                                buffer.append(converter.int8_to_bytes((int8) (value >> 28 | 0x80)).get_data());
                                if (value >> 42 == 0) {
                                    buffer.append(converter.int8_to_bytes((int8) (value >> 35)).get_data());
                                } else {
                                    buffer.append(converter.int8_to_bytes((int8) (value >> 35 | 0x80)).get_data());
                                    if (value >> 49 == 0) {
                                        buffer.append(converter.int8_to_bytes((int8) (value >> 42)).get_data());
                                    } else {
                                        buffer.append(converter.int8_to_bytes((int8) (value >> 42 | 0x80)).get_data());
                                        if (value >> 56 == 0) {
                                            buffer.append(converter.int8_to_bytes((int8) (value >> 49)).get_data());
                                        } else {
                                            buffer.append(converter.int8_to_bytes((int8) (value >> 49 | 0x80)).get_data());
                                            buffer.append(converter.int8_to_bytes((int8) (value >> 56)).get_data());
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