namespace HdrHistogram { 

    void register_zlib() {
        Test.add_func("/HdrHistogram/Zlib/compress", () => {
            //given
            string input = "ABCD";

            //when
            var compressed = Zlib.compress(input.data);
 
            //expect
            var encoded_compressed = Base64.encode((uchar[]) compressed);

            assert(encoded_compressed == "eJxzdHJ2AQACmAEL");
        });

        Test.add_func("/HdrHistogram/Compressor/decompress", () => {
            //given
            var input = (uint8[]) Base64.decode("eJxzdHJ2AQACmAEL");

            //when
            var decompressed = Zlib.decompress(input);

            //then
            stdout.printf("(string) decompressed %s\n", (string) decompressed);
            stdout.flush();
            assert("ABCD" == (string) decompressed);
        });
    }
}