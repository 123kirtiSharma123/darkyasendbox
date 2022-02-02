public with sharing class HTMLParser {
	
	// return a list of pseudo objects defined by specified primary tag (object) and list of child tags (fields)
	static public List<Map<String,List<String>>> parse(String html, String parentTag, List<String> childTags, Map<String,List<String>> childTagAttributes, Map<String,integer> childTagOccurrence) {
		
		List<Map<String,List<String>>> objects = new List<Map<String,List<String>>>();
		integer idx = 0; // tracks the current position in the file (cursor position)
		integer eof = html.length();
		
		integer parentTagLen = parentTag.length();
		
		integer parentTagFragmentEnd = parentTag.indexOf(' ');
		if (parentTagFragmentEnd < 0) {
			parentTagFragmentEnd = parentTag.indexOf('>');
            if (parentTagFragmentEnd < 0) parentTagFragmentEnd = parentTag.length();
		}
		
		String parentTagFragment = parentTag.left(parentTagFragmentEnd);
	
		String parentTagClose = parentTagFragment.replace('<','</') + '>';
		
		integer parentTagCloseLen = parentTagClose.length();
		
		while (idx <= eof) {
			idx = html.indexOf(parentTag,idx);
			
			if (idx == -1) {
				return objects;
			}
			integer objectEndIdx;
			
			integer nextParentTagFragment = html.indexOf(parentTagFragment,idx + 1);
			
			integer nextCloseTag = html.indexOf(parentTagClose,idx + 1);
			
			if (nextParentTagFragment > 0 
					&& nextCloseTag > 0 
					&& nextParentTagFragment < nextCloseTag) {
				
				while (nextParentTagFragment > 0 
						&& nextCloseTag > 0
							&& nextParentTagFragment < nextCloseTag) {
					nextCloseTag = html.indexOf(parentTagClose,nextCloseTag + 1);
				
					nextParentTagFragment = html.indexOf(parentTagFragment,nextParentTagFragment + 1);
					
				} // end while
			} // end if
            
			objectEndIdx = (nextCloseTag + parentTagCloseLen);
			
			String parentTagEnclosure = html.substring(idx,objectEndIdx);
			
			Map<String,List<String>> tagValueMap = new Map<String,List<String>>();
			// assumption is the first child tag will be the key for the map
			for (String s : childTags) {
				tagValueMap.put(s,new List<String>());
				Boolean findChildByFragment = false;
				
				integer childTagFragmentEnd = s.indexOf(' ');
				if (childTagFragmentEnd == -1) {
					childTagFragmentEnd = s.indexOf('>');
					if (childTagFragmentEnd == -1) {
						findChildByFragment = true;
						childTagFragmentEnd = s.length();
					}
				} 
				
				String childTagFragment = s.left(childTagFragmentEnd);
			
				integer childTagLen = s.length();
				
				String childTagClose = childTagFragment.replace('<','</') + '>';
				
				integer childObjectIdx = parentTagEnclosure.indexOf(s);
              
				if (childTagOccurrence != null && childTagOccurrence.containsKey(s) && childTagOccurrence.get(s) != null) {
					
                    if (childTagOccurrence.get(s) > 1) {
						for (integer j=2;j <= childTagOccurrence.get(s);j++) {
							childObjectIdx = parentTagEnclosure.indexOf(s,childObjectIdx + 1);
                         
						}
					}
				}
				
				if (childObjectIdx == -1) continue; 
				integer childTagEnd = parentTagEnclosure.indexOf('>',childObjectIdx);
				
				integer childObjectEndIdx = parentTagEnclosure.indexOf(childTagClose,childObjectIdx + childTagLen);
			
				String childTagEnclosure = parentTagEnclosure.substring(childObjectIdx, childObjectEndIdx + childTagClose.length());
			
				integer valueReadStart = (childTagEnd + 1);
			
				integer valueReadEnd = childObjectEndIdx;
				
				String tagValue = parentTagEnclosure.substring(valueReadStart,valueReadEnd);
            
				if (childTagAttributes != null && childTagAttributes.containsKey(s) && childTagAttributes.get(s) != null) {
				
                    for (String t : childTagAttributes.get(s)) {
						if (!String.isBlank(t)) {
							tagValue = getAttributeValue(childTagEnclosure,t);
                           
						}
						tagValue = removeComments(tagValue);
						tagValue = tagValue.trim();
					
						tagValueMap.get(s).add(tagValue);
					}
				} else {
					tagValue = removeComments(tagValue);
					tagValue = tagValue.trim();
					
					tagValueMap.get(s).add(tagValue);
				}
			} // end while
		
			objects.add(tagValueMap);
			idx = objectEndIdx;
			
		} // end while
		
		return objects;
	}
    static public String formatHtml(String html, String parentTag) {
	system.debug('htmlhtmlhtmlhtml'+html);
		
        String  myHtml = '';
		List<Map<String,List<String>>> objects = new List<Map<String,List<String>>>();
		integer idx = 0; // tracks the current position in the file (cursor position)
		integer eof = html.length();
	
		integer parentTagLen = parentTag.length();
		
		integer parentTagFragmentEnd = parentTag.indexOf(' ');
		if (parentTagFragmentEnd < 0) {
			parentTagFragmentEnd = parentTag.indexOf('>');
            if (parentTagFragmentEnd < 0) parentTagFragmentEnd = parentTag.length();
		}
	
		String parentTagFragment = parentTag.left(parentTagFragmentEnd);
		system.debug('parentTagFragment'+parentTagFragment);
		String parentTagClose = parentTagFragment.replace('<','</') + '>';
		
		integer parentTagCloseLen = parentTagClose.length();
		
		while (idx <= eof) {
			idx = html.indexOf(parentTag,idx);
		
			if (idx == -1) {
				return myHtml;
			}
            
			integer objectEndIdx;
			
			integer nextParentTagFragment = html.indexOf(parentTagFragment,idx + 1);
			
			integer nextCloseTag = html.indexOf(parentTagClose,idx + 1);
			
			if (nextParentTagFragment > 0 
					&& nextCloseTag > 0 
					&& nextParentTagFragment < nextCloseTag) {
				
				while (nextParentTagFragment > 0 
						&& nextCloseTag > 0
							&& nextParentTagFragment < nextCloseTag) {
					nextCloseTag = html.indexOf(parentTagClose,nextCloseTag + 1);
				
					nextParentTagFragment = html.indexOf(parentTagFragment,nextParentTagFragment + 1);
					
				} // end while
			} // end if
            
			objectEndIdx = (nextCloseTag + parentTagCloseLen);
			
			String parentTagEnclosure = html.substring(idx,objectEndIdx);
			system.debug('objectEndIdx'+objectEndIdx);
            
            String toBeChild ='';
            if(nextParentTagFragment > -1){
                 
                 toBeChild = html.substring(objectEndIdx,nextParentTagFragment);
            }
            else
            {
				
             	toBeChild = html.substring(objectEndIdx,eof);                
            }
              myHtml +=parentTag + toBeChild + parentTagClose; 
           
			Map<String,List<String>> tagValueMap = new Map<String,List<String>>();
			
			idx = objectEndIdx;
			
		} // end while
		System.debug('myHtmlmyHtmlmyHtml'+myHtml);
		return myHtml;
	}
	public static String removeComments(String s) {
		integer sLen = s.length();
		
		String stringToReturn;
		integer commentLoc = s.indexOf('<!--');
				if (commentLoc >= 0) {
			stringToReturn = s.left(commentLoc);
			
			integer commentEnd = s.indexOf('-->',commentLoc) + 3;
			
			stringToReturn = (stringToReturn + s.right(sLen - commentEnd));
		
			if (stringToReturn.indexOf('<!--') >= 0) {
				stringToReturn = removeComments(stringToReturn);
			} 
		} else {
			stringToReturn = s;
		}
		return stringToReturn;
	}

	public static String getAttributeValue(String tagValue, String attributeName) {
		String valueToReturn = '';
		
		if (!String.isBlank(tagValue) && !String.isBlank(attributeName)) {
			integer attributeIdx = tagValue.indexOf(attributeName);
			if (attributeIdx >= 0) {
				integer valueStart = tagValue.indexOf('"',attributeIdx) + 1;
				integer valueEnd = tagValue.indexOf('"',valueStart + 1);
				if (valueStart >= 0 && valueEnd >= 0) {
					valueToReturn = tagValue.substring(valueStart,valueEnd);
				}
			}
		}
		
		return valueToReturn;
	}

}