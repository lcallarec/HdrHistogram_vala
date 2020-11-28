namespace HdrHistogram { 

    /*
     * Replacement for java.util.Iterator<R>
     */
    public interface Iterator<E> {
        //TODO: should retrun bool to be vala complient ; and a get method to return current element
        public abstract E next();
        public abstract bool has_next();
        public abstract void remove();
    }
}