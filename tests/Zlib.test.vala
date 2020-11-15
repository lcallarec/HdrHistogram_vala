namespace HdrHistogram { 

    void register_zlib() {
        Test.add_func("/HdrHistogram/Zlib", () => {
            //given
            string input = "ABCDE";

            //when
            var compressed = Zlib.compress(input.data);
            var decompressed = Zlib.decompress(compressed);
            
            //expect
            assert((string) decompressed == input);
        });
    }
}