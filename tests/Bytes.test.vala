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
    }
}
