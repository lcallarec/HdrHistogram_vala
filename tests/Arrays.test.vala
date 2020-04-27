namespace HdrHistogram { 

    void register_int64_arrays() {
        Test.add_func("/HdrHistogram/Arrays/Int64/copy#same_size", () => {
            //given
            int64[] original_array = {1, 2, 3};

            //when
            var copy = Arrays.Int64.copy(original_array, 3);

            //then
            assert(original_array.length == 3);
            assert(copy.length == original_array.length);
            for (var i = 0; i < original_array.length; i++) {
                assert(original_array[i] == copy[i]);
            }
        });

        Test.add_func("/HdrHistogram/Arrays/Int64/copy#smaller_than_original", () => {
            //given
            int64[] original_array = {1, 2, 3};
            var copy_len = 1;

            //when
            var copy = Arrays.Int64.copy(original_array, copy_len);

            //then
            assert(original_array.length == 3);
            assert(copy_len == copy.length);
            for (var i = 0; i < copy_len; i++) {
                assert(original_array[i] == copy[i]);
            }
        });
        
        Test.add_func("/HdrHistogram/Arrays/Int64/copy#larger_than_original", () => {
            //given
            int64[] original_array = {1, 2, 3};
            var copy_len = 5;

            //when
            var copy = Arrays.Int64.copy(original_array, copy_len);

            //then
            assert(original_array.length == 3);
            assert(copy_len == copy.length);
            for (var i = 0; i < original_array.length; i++) {
                assert(original_array[i] == copy[i]);
            }
            assert(copy[3] == 0);
            assert(copy[4] == 0);
            
        });  

        Test.add_func("/HdrHistogram/Arrays/Int64/fill", () => {
            //given
            int64[] original_array = {1, 2, 3, 4, 5, 6, 7, 8, 9};

            //when
            Arrays.Int64.fill(original_array, 1, 5, 10);

            //then
            assert(original_array[0] == 1);
            assert(original_array[1] == 10);
            assert(original_array[2] == 10);
            assert(original_array[3] == 10);
            assert(original_array[4] == 10);
            assert(original_array[5] == 6);
            assert(original_array[6] == 7);
            assert(original_array[7] == 8);
            assert(original_array[8] == 9);
        });

        Test.add_func("/HdrHistogram/Arrays/Int64/copy_to", () => {
            //given
            int64[] source_array = {10, 20, 30, 40, 50, 60, 70, 80, 90, 100};
            int64[] destination_array = { 15, 25, 35, 45, 55, 65, 75, 85, 95, 105}; 

            //when
            Arrays.Int64.array_copy(source_array, 3, destination_array, 5, 4);

            //then
            int64[] expected = {15, 25, 35, 45, 55, 40, 50, 60, 70, 105};

            for(var i = 0; i < source_array.length; i++) {
                assert(destination_array[i] == expected[i]);
            }
        });

        Test.add_func("/HdrHistogram/Arrays/Bytes/concat", () => {
            //given
            uint8[] array1 = {0, 1, 2};
            uint8[] array2 = {2, 3, 4}; 

            //when
            Arrays.Bytes.concat(ref array1, array2);

            //then
            int64[] expected = {0, 1, 2, 2, 3, 4};

            assert(array1.length == 6);
            for(var i = 0; i < array1.length; i++) {
                assert(array1[i] == expected[i]);
            }
        });

        Test.add_func("/HdrHistogram/Arrays/Bytes/reverse", () => {
            //given
            uint8[] array1 = {0, 1, 2};

            //when
            var result = Arrays.Bytes.reverse(array1);

            //then
            int64[] expected = {2, 1, 0};

            assert(result.length == 3);
        });
    }
}