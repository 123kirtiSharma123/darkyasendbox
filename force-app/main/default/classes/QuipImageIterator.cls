public class QuipImageIterator implements iterable<QuipImageWrapper>{
    List<QuipImageWrapper> wrappers;

    public QuipImageIterator(){
        wrappers = new List<QuipImageWrapper>();
    }

    public QuipImageIterator(List<QuipImageWrapper> wrappers){
        this();
        this.wrappers = wrappers;
    }

    public Iterator<QuipImageWrapper> Iterator(){ 
        return new QuipImageIterableList(wrappers);      
    }

    public class QuipImageWrapper{
        public String fileTitle {get; set;}
        public String quipImageUrl {get; set;}
        public String parentId {get; set;}
    }
}