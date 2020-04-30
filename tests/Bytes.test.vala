namespace HdrHistogram { 

    void register_bytes() {
        Test.add_func("/HdrHistogram/ByteArrayWriter#ByteOrder.BIG_ENDIAN)", () => {
            //given
             var writer = new ByteArrayWriter(ByteOrder.BIG_ENDIAN);

            //when
            writer.put_int32(1024);

            //then
            assert(writer.position == 4);

            assert(new Bytes.take(writer.to_byte_array().data).compare(new Bytes.take({0, 0, 4, 0})) == 0);

            //when
            writer.put_int64(12);

            //then
            assert(writer.position == 12);
            assert(new Bytes.take(writer.to_byte_array().data).compare(new Bytes.take({0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 12})) == 0);

            //when
            writer.put_double(1);

            //then
            assert(writer.position == 20);
            assert(new Bytes.take(writer.to_byte_array().data).compare(new Bytes.take({0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 12, 63, 240, 0, 0, 0, 0, 0, 0})) == 0);
        });

        Test.add_func("/HdrHistogram/BytesArrayReader#ByteOrder.BIG_ENDIAN", () => {
            //given
            var writer = new ByteArrayWriter(ByteOrder.BIG_ENDIAN);            
            writer.put_int8(127);
            writer.put_int8(12);
            writer.put_int32(57897);
            writer.put_int32(int32.MAX);
            writer.put_int64(987455678);
            writer.put_int64(int64.MAX);
            writer.put_double(3.94);
            writer.put_int8(100);

            //when
            var reader = new ByteArrayReader(writer.to_byte_array(), ByteOrder.BIG_ENDIAN);

            //then
            assert(reader.read_int8() == 127);
            assert(reader.read_int8() == 12);
            assert(reader.read_int32() == 57897);
            assert(reader.read_int32() == int32.MAX);
            assert(reader.read_int64() == 987455678);
            assert(reader.read_int64() == int64.MAX);
            assert(reader.read_double() == 3.94);
            assert(reader.read_int8() == 100);
        });

        Test.add_func("/HdrHistogram/BytesArrayReader#ByteOrder.LITTLE_ENDIAN", () => {
            //given
            var writer = new ByteArrayWriter(ByteOrder.LITTLE_ENDIAN);            
            writer.put_int8(127);
            writer.put_int8(12);
            writer.put_int32(57897);
            writer.put_int32(int32.MAX);
            writer.put_int64(987455678);
            writer.put_int64(int64.MAX);
            writer.put_double(3.94);
            writer.put_int8(100);

            //when
            var reader = new ByteArrayReader(writer.to_byte_array(), ByteOrder.LITTLE_ENDIAN);

            //then
            assert(reader.read_int8() == 127);
            assert(reader.read_int8() == 12);
            assert(reader.read_int32() == 57897);
            assert(reader.read_int32() == int32.MAX);
            assert(reader.read_int64() == 987455678);
            assert(reader.read_int64() == int64.MAX);
            assert(reader.read_double() == 3.94);
            assert(reader.read_int8() == 100);
        });
    }
}
