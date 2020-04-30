namespace HdrHistogram { 

    void register_zig_zag_encoding() {
        Test.add_func("/HdrHistogram/ZigZag/encoder", () => {
            // given
            var encoder = new ZigZag.Encoder();

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

        Test.add_func("/HdrHistogram/ZigZag/decoder", () => {
            // given
            var encoder = new ZigZag.Encoder();
            encoder.encode_int64(0);
            encoder.encode_int64(27);
            encoder.encode_int64(int64.MAX/10);

            //when
            var decoder = new ZigZag.Decoder(encoder.to_byte_array());

            // then
            assert(decoder.decode_int64() == 0);
            assert(decoder.decode_int64() == 27);
            assert(decoder.decode_int64() == int64.MAX/10);
  
        });
    }
}