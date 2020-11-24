namespace HdrHistogram { 

    void main (string[] args) {

        Test.init(ref args);

        register_int8_arrays();
        register_int16_arrays();
        register_int32_arrays();
        register_int64_arrays();
        register_array_bytes();
        register_int64();
        register_zig_zag_encoding();
        register_histogram();
        register_int8_histogram();
        register_int16_histogram();
        register_int32_histogram();
        register_bytes();
        register_zlib();
        
        Test.run();
    }
}