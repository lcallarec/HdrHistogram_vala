namespace HdrHistogram.Arrays.Int64 { 
    
    //Generics aren't used here, due to a vala compiler bug which cause array data to be corrupted

    //Replacement for java Arrays.copy
    internal int64[] copy(int64[] array, int new_length) {
        if (new_length <= array.length) {
            return array[0:new_length];
        }
        array.resize(new_length);
        return array;
    }

    //Replacement for java Arrays.fill
    internal void fill(int64[] array, int64 from, int64 to, int64 value) {
        for (var i = from; i < to; i++) {
            array[i] = value;
        }
    }

    //Replacement for java System.arraycopy
    internal void array_copy(int64[] source, int64 source_pos, int64[] dest, int64 dest_pos, int64 len) {
        for (var i = source_pos; i < source_pos + len; i++) {
            dest[dest_pos++] = source[i];
        }
    }
}