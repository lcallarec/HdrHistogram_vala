namespace HdrHistogram {

    public ByteOrder get_host_endianness() {
        int num = 1;
        if(*(char *)&num == 1) {
            return ByteOrder.LITTLE_ENDIAN;
        }
        return ByteOrder.BIG_ENDIAN;
    }

    public class ByteArrayWriter {
        private ByteOrder endianness;
        private ByteConverter converter;
        private uint8[] buffer = new uint8[]{};
        public int position { get; set; default = 0; }

        public ByteArrayWriter(ByteOrder endianness = ByteOrder.HOST) {
            if (endianness == ByteOrder.HOST) {
                this.endianness = get_host_endianness();
            } else {
                this.endianness = endianness;
            }
            converter = new ByteConverter(endianness);
        }

        public void put_int8(int8 value) {
            buffer.resize(position + 1);
            var bytes = converter.int8_to_bytes(value);
            buffer[position] = bytes[0];
            position++;
        }

        public void put_int32(int32 value) {
            buffer.resize(position + 4);
            var bytes = converter.int32_to_bytes(value);
            for (var i = 0; i < 4; i++) {
                buffer[position + i] = bytes[i];
            }
            position += 4;
        }

        public void put_int64(int64 value) {
            buffer.resize(position + 8);
            var bytes = converter.int64_to_bytes(value);
            for (var i = 0; i < 8; i++) {
                buffer[position + i] = bytes[i];
            }
            position += 8;
        }

        public void put_double(double value) {
            buffer.resize(position + 8);
            var bytes = converter.double_to_bytes(value);
            for (var i = 0; i < 8; i++) {
                buffer[position + i] = bytes[i];
            }
            position += 8;
        }

        public void put_byte_array(ByteArray byte_array) {
            buffer.resize(position + (int) byte_array.len);
            for (var i = 0; i < byte_array.len; i++) {
                buffer[position + i] = byte_array.data[i];
            }
            position += (int) byte_array.len;
        }

        public void put_bytes(uint8[] bytes) {
            buffer.resize(position + bytes.length);
            for (var i = 0; i < bytes.length; i++) {
                buffer[position + i] = bytes[i];
            }
            position += (int) bytes.length;
        }

        public ByteArray to_byte_array() {
            return new ByteArray.take(buffer);
        }
    }

    internal class ByteConverter {
        private ByteOrder endianness;
        private ByteOrder host_endianness = get_host_endianness();

        public ByteConverter(ByteOrder endianness) {
            this.endianness = endianness;
        }

        public uint8[] int8_to_bytes(int8 value) {
            int8 v = value;
            uint8[] bytes = (uint8[])&v;
            return bytes;
        }
    
        public uint8[] int32_to_bytes(int value) {
            int v = value;
            if (endianness == ByteOrder.BIG_ENDIAN) {
                v = value.to_big_endian();
            }
            if (endianness == ByteOrder.LITTLE_ENDIAN) {
                v = value.to_little_endian();
            }
            uint8[] bytes = (uint8[])&v;
            return bytes;
        }
    
        public uint8[] int64_to_bytes(int64 value) {
            int64 v = value;
            if (endianness == ByteOrder.BIG_ENDIAN) {
                v = value.to_big_endian();
            }
            if (endianness == ByteOrder.LITTLE_ENDIAN) {
                v = value.to_little_endian();
            }
            uint8[] bytes = (uint8[])&v;
            return bytes;
        }
    
        public uint8[] double_to_bytes(double value) {
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
            
            return be_bytes;
        }
    }

    public class ByteArrayReader {
        public int position { get; set; default = 0; }
        private ByteOrder endianness;
        private uint8[] buffer;

        public ByteArrayReader(ByteArray buffer, ByteOrder endianness = get_host_endianness()) {
            this.buffer = buffer.data;
            this.endianness = endianness;
        }

        public int read_int8() {
            return buffer[position++];
        }

        public int read_int32() {
            var bytes = buffer[position:position+4];
            position += 4;
            if (endianness == ByteOrder.BIG_ENDIAN) {
                return (bytes[0] << 24) + (bytes[1] << 16) + (bytes[2] << 8) + bytes[3];
            }

            return bytes[0] + (bytes[1] << 8) + (bytes[2] << 16) + (bytes[3] << 24);
        }

        public int64 read_int64() {
            var bytes = buffer[position:position+8];
            position += 8;
            if (endianness == ByteOrder.BIG_ENDIAN) {
                return ((int64) bytes[0] << 56) + ((int64)bytes[1] << 48) + ((int64)bytes[2] << 40) + ((int64)bytes[3] << 32) + ((int64)bytes[4] << 24) + ((int64)bytes[5] << 16) + ((int64)bytes[6] << 8) + (int64)bytes[7];
            }

            return ((int64) bytes[0]) + ((int64)bytes[1] << 8) + ((int64)bytes[2] << 16) + ((int64)bytes[3] << 24) + ((int64)bytes[4] << 32) + ((int64)bytes[5] << 40) + ((int64)bytes[6] << 48) + ((int64)bytes[7] << 56);
        }

        public double read_double() {
            uint8[] bytes = buffer[position:position+8];
            position += 8;

            int64 v;
            if (endianness == ByteOrder.BIG_ENDIAN) {
                v = ((int64) bytes[0] << 56) + ((int64)bytes[1] << 48) + ((int64)bytes[2] << 40) + ((int64)bytes[3] << 32) + ((int64)bytes[4] << 24) + ((int64)bytes[5] << 16) + ((int64)bytes[6] << 8) + (int64)bytes[7];
            } else {
                v = ((int64) bytes[0]) + ((int64)bytes[1] << 8) + ((int64)bytes[2] << 16) + ((int64)bytes[3] << 24) + ((int64)bytes[4] << 32) + ((int64)bytes[5] << 40) + ((int64)bytes[6] << 48) + ((int64)bytes[7] << 56);
            }

            double* f = (double *)(&v);
            return *f;
        }
    }
}