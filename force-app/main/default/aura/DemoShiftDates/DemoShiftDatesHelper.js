({
    refreshObjectItems : function(component, event, helper) {
        let initAction = component.get("c.getObjectItems");
        initAction.setCallback(this, function(response) {
            switch (response.getState()) {
                case "SUCCESS" :
                    component.set("v.objectList", response.getReturnValue());
                    helper.refreshTotals (response.getReturnValue(), component, event, helper);
                    break;
            }
        });
        $A.enqueueAction(initAction);        		
    },
    
    refreshTotals : function(rows, component, event, helper) {
        let totalRecords = 0;
        for (const row of rows)
            totalRecords += row.itemCount;
        component.set("v.totalRecords", totalRecords);    
    },
    
    getMinutesToShift : function(component, event, helper) {
        let action = component.get("c.getMinutesToShift");
        const dateISO = component.find("demoDate").get("v.value");
        const condition = component.find("lastCriterionSelected").get("v.value");
        action.setParams({
            dateOfDemo: dateISO.substring(0,4) + "-" + dateISO.substring(5,7) + "-" + dateISO.substring(8,10) + " " + dateISO.substring(11,13) + ":" + dateISO.substring(14,16) + ":" + dateISO.substring(17,19),
            condition: condition == null ? "Last Office Visit Exit" : condition
        });
        action.setCallback(this, function(response) {
            switch (response.getState()) {
                case "SUCCESS" :               
                    component.set("v.minutesToShift", response.getReturnValue());
                    break;
            }
        });
        $A.enqueueAction(action);
    },
    
    dateShiftEventCallback : function(component, eventReceived, helper) {
        const sObjectAPI = eventReceived.data.payload.SObject_API_Name__c;
        const runningTotal = eventReceived.data.payload.Running_Total__c;
        const numberOfErrors = eventReceived.data.payload.Errors__c;
        let dateShiftFinished = true;
        let dateShiftHadErrors = false;
        let objectList = component.get("v.objectList");
        for (let dso of objectList) {
            if (dso.itemAPIName == sObjectAPI) {
            	dso.itemRunningTotal = runningTotal;
            	dso.itemNumberOfErrors = numberOfErrors;
            	dso.itemShiftFinished = runningTotal >= dso.itemCount;	
        	}
            dateShiftFinished = dateShiftFinished && dso.itemShiftFinished;
            dateShiftHadErrors = dateShiftHadErrors || dso.itemNumberOfErrors > 0;
        }
        component.set("v.dateShiftFinished", dateShiftFinished);
        component.set("v.dateShiftHadErrors", dateShiftHadErrors);
        component.set("v.objectList", objectList);
        if (dateShiftFinished) {
            component.find("empApi").unsubscribe(component.get("v.subscription"), $A.getCallback(unsubscribed => {
                component.set("v.subscription", null);
            }));
            if (dateShiftHadErrors)
            	component.find("notifLib").showToast({
            		mode : "sticky",
            		variant : "error",
            		message : "Errors occurred during the date shift. Please check the system debug log for details.\n" +
                    		  "All records without errors were date shifted correctly."
        		});                
            component.find("notifLib").showToast({
            	mode : "sticky",
            	variant : "success",
            	title : "Date shifting has completed.",
            	message : "Make sure that you run the Einstein Analytics dataflows that contain the records you shifted so that your dashboards will reflect the shifted dates.\n" +
                      	  "If you have any questions about how to do that, please consult one of your team's Einstein Analytics Blackbelts."
        	});
        }
    }
})