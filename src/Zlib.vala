namespace HdrHistogram.Zlib { 

    public errordomain ZlibError {
        COMPRESSION_LEVEL_OUT_OF_RANGE
    }

    public static uint8[] compress(uint8[] input, int level = -1) throws HdrError {
        var mistream = new MemoryInputStream.from_data(input);
        ZlibCompressor converter = new ZlibCompressor(ZlibCompressorFormat.ZLIB, level);

        var cistream = new ConverterInputStream(mistream, converter);
        DataInputStream distream = new DataInputStream (cistream);

        uint8[] output = {};
        while(true) {
            try {
                var bytes = distream.read_bytes(1);
                if (bytes.get_size() == 0) break;
                Arrays.Bytes.concat(ref output, bytes.get_data());
            } catch (GLib.Error e) {
                throw new HdrError.COMPRESS_ERROR("Error while compressing data : %s".printf(e.message));
            }
        }

        return output;
    }

    public static uint8[] decompress(uint8[] input) throws HdrError {        
        var mistream = new MemoryInputStream.from_data(input);
        ZlibDecompressor converter = new ZlibDecompressor(ZlibCompressorFormat.ZLIB);

        var cistream = new ConverterInputStream(mistream, converter);
        DataInputStream distream = new DataInputStream (cistream);

        uint8[] output = {};
        while(true) {
            try {
                var bytes = distream.read_bytes(input.length);
                if (bytes.get_size() == 0) break;
                Arrays.Bytes.concat(ref output, bytes.get_data());
            } catch (GLib.Error e) {
                throw new HdrError.COMPRESS_ERROR("Error while decompressing data : %s".printf(e.message));
            }
        }

        return output;
    }
}   