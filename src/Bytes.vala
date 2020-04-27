namespace HdrHistogram { 

    public class BytesConverter {
        private ByteOrder endianness;
        private ByteOrder host_endianness = BytesConverter.get_host_endianness();

        public BytesConverter(ByteOrder endianness) {
            this.endianness = endianness;
        }

        public Bytes int8_to_bytes(int8 value) {
            int8 v = value;
            uint8[] bytes = (uint8[])&v;
            return new Bytes.take(bytes);
        }
    
        public Bytes int_to_bytes(int value) {
            int v = value;
            if (endianness == ByteOrder.HOST) {
                v = value;
            }
            if (endianness == ByteOrder.BIG_ENDIAN) {
                v = value.to_big_endian();
            }
            if (endianness == ByteOrder.LITTLE_ENDIAN) {
                v = value.to_little_endian();
            }
            uint8[] bytes = (uint8[])&v;
            return new Bytes.take(bytes);
        }
    
        public Bytes int64_to_bytes(int64 value) {
            int64 v = value;
            if (endianness == ByteOrder.HOST) {
                v = value;
            }
            if (endianness == ByteOrder.BIG_ENDIAN) {
                v = value.to_big_endian();
            }
            if (endianness == ByteOrder.LITTLE_ENDIAN) {
                v = value.to_little_endian();
            }
            uint8[] bytes = (uint8[])&v;
            return new Bytes.take(bytes);
        }
    
        public Bytes double_to_bytes(double value) {
            double v = value;
            uint8[] bytes = (uint8[])&v;
            var be_bytes = bytes;
            if (endianness == ByteOrder.HOST) {
                be_bytes = bytes;
            }
            if (endianness == ByteOrder.BIG_ENDIAN && endianness != host_endianness) {
                be_bytes = Arrays.Bytes.reverse(bytes);
            }
            if (endianness == ByteOrder.LITTLE_ENDIAN && endianness != host_endianness) {
                be_bytes = Arrays.Bytes.reverse(bytes);
            }
            
            return new Bytes.take(be_bytes);
        }

        private static ByteOrder get_host_endianness() {
            int num = 1;
            if(*(char *)&num == 1) {
                return ByteOrder.LITTLE_ENDIAN;
            }
            return ByteOrder.BIG_ENDIAN;
        }
    }
}