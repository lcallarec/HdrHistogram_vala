namespace HdrHistogram { 

    /*
     * Replacement for java.util.Iterator<R>
     */
    public interface Iterator<E> {
        public abstract E next() throws HdrError;
        public abstract bool has_next() throws HdrError;
        public abstract void remove();
    }
}