namespace HdrHistogram.Arrays.Int64 { 
    
    //Generics aren't used here, due to a vala compiler bug which cause array data to be corrupted

    //Replacement for java Arrays.copy
    internal int64[] copy(int64[] array, int new_length) {
        if (new_length <= array.length) {
            return array[0:new_length];
        }
        var new_array = array;
        new_array.resize(new_length);
        return new_array;
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

namespace HdrHistogram.Arrays.Bytes { 
    internal void concat(ref uint8[] array1, uint8[] array2) {
        var original_len = array1.length;
        array1.resize(array1.length + array2.length);
        for (var i = 0; i < array2.length; i++) {
            array1[original_len + i] = array2[i];
        }
    }

    internal uint8[] reverse(uint8[] array1) {
        uint8[] reversed = {};
        for (var i = array1.length - 1; i >= 0; i--) {
            reversed += array1[i];
        }

        return reversed;
    }
}

namespace HdrHistogram.Arrays.Int8 { 
    
    //Generics aren't used here, due to a vala compiler bug which cause array data to be corrupted

    //Replacement for java Arrays.copy
    internal int8[] copy(int8[] array, int new_length) {
        if (new_length <= array.length) {
            return array[0:new_length];
        }
        var new_array = array;
        new_array.resize(new_length);
        return new_array;
    }

    //Replacement for java Arrays.fill
    internal void fill(int8[] array, int64 from, int64 to, int8 value) {
        for (var i = from; i < to; i++) {
            array[i] = value;
        }
    }

    //Replacement for java System.arraycopy
    internal void array_copy(int8[] source, int64 source_pos, int8[] dest, int64 dest_pos, int64 len) {
        for (var i = source_pos; i < source_pos + len; i++) {
            dest[dest_pos++] = source[i];
        }
    }
}

namespace HdrHistogram.Arrays.Int16 { 
    
    //Generics aren't used here, due to a vala compiler bug which cause array data to be corrupted

    //Replacement for java Arrays.copy
    internal int16[] copy(int16[] array, int new_length) {
        if (new_length <= array.length) {
            return array[0:new_length];
        }
        var new_array = array;
        new_array.resize(new_length);
        return new_array;
    }

    //Replacement for java Arrays.fill
    internal void fill(int16[] array, int64 from, int64 to, int16 value) {
        for (var i = from; i < to; i++) {
            array[i] = value;
        }
    }

    //Replacement for java System.arraycopy
    internal void array_copy(int16[] source, int64 source_pos, int16[] dest, int64 dest_pos, int64 len) {
        for (var i = source_pos; i < source_pos + len; i++) {
            dest[dest_pos++] = source[i];
        }
    }
}

namespace HdrHistogram.Arrays.Int32 { 
    
    //Generics aren't used here, due to a vala compiler bug which cause array data to be corrupted

    //Replacement for java Arrays.copy
    internal int32[] copy(int32[] array, int new_length) {
        if (new_length <= array.length) {
            return array[0:new_length];
        }
        var new_array = array;
        new_array.resize(new_length);
        return new_array;
    }

    //Replacement for java Arrays.fill
    internal void fill(int32[] array, int64 from, int64 to, int32 value) {
        for (var i = from; i < to; i++) {
            array[i] = value;
        }
    }

    //Replacement for java System.arraycopy
    internal void array_copy(int32[] source, int64 source_pos, int32[] dest, int64 dest_pos, int64 len) {
        for (var i = source_pos; i < source_pos + len; i++) {
            dest[dest_pos++] = source[i];
        }
    }
}