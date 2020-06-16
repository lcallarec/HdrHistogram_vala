namespace HdrHistogram { 

    /*
     * Replacement for java.util.Iterator<R>
     */
    public interface Iterator<E> {
        //TODO: should retrun bool to be vala complient ; and a get method to return current element
        public abstract E next() throws HdrError;
        public abstract bool has_next() throws HdrError;
        public abstract void remove();
    }
}