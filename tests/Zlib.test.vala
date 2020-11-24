namespace HdrHistogram { 

    void register_zlib() {
        Test.add_func("/HdrHistogram/Zlib", () => {
            //given
            string input = "ABCDE";

            try {
                //when
                var compressed = Zlib.compress(input.data);
                var decompressed = Zlib.decompress(compressed);
                //then
                assert((string) decompressed == input);
                
            } catch (Error e) {
                assert_not_reached();
            }
        });
    }
}