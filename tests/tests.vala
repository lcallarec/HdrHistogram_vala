namespace HdrHistogram { 

    void main (string[] args) {

        Test.init(ref args);
        register_int64_arrays();
        register_int64();
        register_histogram();
        register_bytes();
        register_zlib();
        Test.run();
    }
}