public class QuipImageIterableList implements Iterator<QuipImageIterator.QuipImageWrapper>{
    List<QuipImageIterator.QuipImageWrapper> wrappers {get; set;}
   
    Integer i {get; set;} 
        
    public QuipImageIterableList(){ 
        i = 0;
    }
        
    public QuipImageIterableList(List<QuipImageIterator.QuipImageWrapper> wrappers){
        this();
        this.wrappers = wrappers;
    }   

    public boolean hasNext(){ 
        if(i >= wrappers.size()) {
            return false; 
        } else {
            return true; 
        }
    }    

    public QuipImageIterator.QuipImageWrapper next(){ 
        i++; 
        return wrappers[i-1]; 
    }
}