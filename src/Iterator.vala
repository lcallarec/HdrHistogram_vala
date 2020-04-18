namespace HdrHistogram { 

    /*
     * Replacement for java.util.Iterator<R>
     */
    public interface Iterator<E> {
        public abstract E next();
        public abstract bool has_next();
        public abstract void remove();
    }
}