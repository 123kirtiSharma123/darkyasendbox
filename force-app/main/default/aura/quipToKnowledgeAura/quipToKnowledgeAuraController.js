({
    myAction : function(component, event, helper) {

    },

    handleCloseQuickAction: function(component, event){
        $A.get("e.force:closeQuickAction").fire();
    }
})