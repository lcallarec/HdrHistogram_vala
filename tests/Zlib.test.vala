namespace HdrHistogram { 

    void register_zlib() {
        Test.add_func("/HdrHistogram/Zlib/compress", () => {
            //given
            string input = "ABCD";

            //when
            var compressed = Zlib.compress(input.data);
            for(var i = 0; i < compressed.length; i++) {
                stdout.printf("compressed[%d] = %d\n", i, compressed[i]);
            }

            //expect
            var encoded_compressed = Base64.encode((uchar[]) compressed);
            stdout.printf("encoded_compressed = %s\n", encoded_compressed);
            stdout.flush();

            assert(encoded_compressed == "eJxzdHJ2AQACmAEL");
        });

        Test.add_func("/HdrHistogram/Compressor/decompress", () => {
            //given
            var input = (uint8[]) Base64.decode("eJxzdHJ2AQACmAEL");

            //when
            var decompressed = Zlib.decompress(input);
            for(var i = 0; i < decompressed.length; i++) {
                stdout.printf("decompressed[%d] = %d\n", i, decompressed[i]);
            }

            //expect
            //  stdout.printf("encoded_compressed = %s\n", encoded_compressed);
            //  stdout.flush();

            assert("ABCD" == (string) decompressed);
        });
    }
}