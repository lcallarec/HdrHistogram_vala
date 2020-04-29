namespace HdrHistogram { 

    void register_zig_zag_encoding() {
        Test.add_func("/HdrHistogram/ZigZagEncoder/encode_int64", () => {
            // given
            var encoder = new ZigZagEncoder();

            // when
            encoder.encode_int64(27);
            
            // then
            var buffer = encoder.to_byte_array();
            assert(buffer.len == 1);
            assert(buffer.data[0] == 54);

            // and when
            encoder.encode_int64(302);

            // then
            buffer = encoder.to_byte_array();
            assert(buffer.len == 3);
            assert((int8) buffer.data[0] == 54);
            assert((int8) buffer.data[1] == -36);
            assert((int8) buffer.data[2] == 4);
        });
    }
}