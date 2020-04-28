namespace HdrHistogram { 

    void register_bytes() {
        Test.add_func("/HdrHistogram/Bytes", () => {
            //given
            var buffer = new ByteArray.sized(32);
            var converter = new BytesConverter(ByteOrder.BIG_ENDIAN);
            //when
            buffer.append(converter.int_to_bytes(1024).get_data());

            //then
            assert(buffer.len == 4);

            assert(
                new Bytes.take(buffer.data).compare(
                    new Bytes.take({0, 0, 4, 0})
                ) == 0);

            //when
            buffer.append(converter.int64_to_bytes(12).get_data());

            //then
            assert(buffer.len == 12);
            assert(new Bytes.take(buffer.data).compare(new Bytes.take({0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 12})) == 0);

            //when
            buffer.append(converter.double_to_bytes((double) 1).get_data());

            //then
            assert(buffer.len == 20);            
            assert(new Bytes.take(buffer.data).compare(new Bytes.take({0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 12, 63, 240, 0, 0, 0, 0, 0, 0})) == 0);
        });

        Test.add_func("/HdrHistogram/BytesArrayReader", () => {
            //given
            var buffer = new ByteArray.sized(32);
            var converter = new BytesConverter(ByteOrder.BIG_ENDIAN);
            
            //when
            buffer.append(converter.int8_to_bytes(127).get_data());
            buffer.append(converter.int8_to_bytes(12).get_data());
            buffer.append(converter.int_to_bytes(57897).get_data());
            buffer.append(converter.int_to_bytes(int32.MAX).get_data());
            buffer.append(converter.int64_to_bytes(987455678).get_data());
            buffer.append(converter.int64_to_bytes(int64.MAX).get_data());
            buffer.append(converter.double_to_bytes(3.94).get_data());
            buffer.append(converter.int8_to_bytes(100).get_data());            
            
            var reader = new BytesArrayReader(buffer);

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
