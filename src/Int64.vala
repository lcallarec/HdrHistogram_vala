namespace HdrHistogram.Int64 { 
    // Replacement for java Long.numberOfLeadingZeros(i)
    // adapted from https://hg.openjdk.java.net/jdk8/jdk8/jdk/file/687fd7c7986d/src/share/classes/java/lang/Long.java
    internal int number_of_leading_zeros(int64 i) {
        if (i == 0)
            return 64;

        int n = 1;
        uint x = (int)( i >> 32); //? int x = (int)(i >>> 32);
        if (x == 0) { n += 32; x = (int)i; }
        if ( x >> 16 == 0) { n += 16; x <<= 16; }
        if ( x >> 24 == 0) { n +=  8; x <<=  8; }
        if ( x >> 28 == 0) { n +=  4; x <<=  4; }
        if (x >> 30 == 0) { n +=  2; x <<=  2; }
        n -= (int) ( x >> 31);

        return n;

    }
}