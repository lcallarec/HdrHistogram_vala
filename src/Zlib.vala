namespace HdrHistogram.Zlib { 

    public errordomain ZlibError {
        COMPRESSION_LEVEL_OUT_OF_RANGE
    }

    public static uint8[] compress(uint8[] input, int level = -1) throws ZlibError {
        if (level < -1 || level > 9) {
            throw new ZlibError.COMPRESSION_LEVEL_OUT_OF_RANGE(@"Compression level should be between -1 (default) and 9");
        } 
        
        var mistream = new MemoryInputStream.from_data(input);
        ZlibCompressor converter = new ZlibCompressor(ZlibCompressorFormat.ZLIB, level);

        var cistream = new ConverterInputStream(mistream, converter);
		DataInputStream distream = new DataInputStream (cistream);

        uint8[] output = {};
        while(true) {
            var bytes = distream.read_bytes(1024);
            if (bytes.get_size() == 0) break;
            Arrays.Bytes.concat(ref output, bytes.get_data());
        }

        return output;
    }

    public static uint8[] decompress(uint8[] input) {        
        var mistream = new MemoryInputStream.from_data(input);
        ZlibDecompressor converter = new ZlibDecompressor(ZlibCompressorFormat.ZLIB);

        var cistream = new ConverterInputStream(mistream, converter);
		DataInputStream distream = new DataInputStream (cistream);

        uint8[] output = {};
        while(true) {
            var bytes = distream.read_bytes(1);
            if (bytes.get_size() == 0) break;
            Arrays.Bytes.concat(ref output, bytes.get_data());
        }

        return output;
    }
}   