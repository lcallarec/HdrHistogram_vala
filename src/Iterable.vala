namespace HdrHistogram { 

    /*
     * Replacement for java.util.Iterable<R>
     */
    public interface Iterable<E> {
        public abstract Iterator<E> iterator();
    }
}