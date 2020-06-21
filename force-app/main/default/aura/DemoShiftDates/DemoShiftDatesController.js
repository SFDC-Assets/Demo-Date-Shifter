({
    doInit : function (component, event, helper) {
        component.set("v.currentDate", (new Date(Date.now())).toISOString());
        component.set("v.columns", [
            { label: "Records", fieldName: "itemCount", type: "number", initialWidth: 100, cellAttributes: { alignment: "center" } },
            { label: "Weekdays Only", fieldName: "itemWeekdaysOnly", type: "boolean", initialWidth: 100, cellAttributes: { alignment: "center" } },
            { label: "Adjust Minutes", fieldName: "itemAdjustMinutes", type: "boolean", initialWidth: 100, cellAttributes: { alignment: "center" } },
            { label: "Object", fieldName: "itemLink", type: "url", cellAttributes: { iconName: "standard:shift" }, typeAttributes: { label: { fieldName: "itemLabel" }, tooltip: { fieldName: "itemLabelPlural" }, target: "_parent" } }
        ]);
        helper.refreshObjectItems (component, event, helper);
        helper.getMinutesToShift (component, event, helper);
    },
    
    handleDateTimeSelect : function (component, event, helper) {
        component.set("v.lastCriterion", component.find("lastCriterionSelected").get("v.value"));
        helper.getMinutesToShift (component, event, helper);        
    },
    
    handleShiftTheDatesButton : function (component, event, helper) {
        component.set("v.modalOpen", true);
    },
    
    handleCancelButton : function (component, event, helper) {
        component.set("v.modalOpen", false);
        component.find("notifLib").showToast({
            message: "No dates were shifted."
        });       
    },
    
    handleShiftDatesButton : function (component, event, helper) {
        component.set("v.modalOpen", false);
        component.set("v.spinnerVisible", true);
        component.find("empApi").subscribe("/event/Date_Shift_Event__e", -1, $A.getCallback(eventReceived => {
			helper.dateShiftEventCallback(component, eventReceived, helper);
        })).then(subscription => {
            console.log('Subscribed to channel ', subscription.channel);
            component.set("v.subscription", subscription);
        });
        let resetDatesAction = component.get("c.dateShift");
        const dateISO = component.find("demoDate").get("v.value");
        resetDatesAction.setParams({
            dateOfDemo : dateISO.substring(0,4) + "-" + dateISO.substring(5,7) + "-" + dateISO.substring(8,10) + " " + dateISO.substring(11,13) + ":" + dateISO.substring(14,16) + ":" + dateISO.substring(17,19),
            condition : component.find("lastCriterionSelected").get("v.value")
        });
        resetDatesAction.setCallback(this, function(response) {
            component.set("v.spinnerVisible", false);
            switch (response.getState()) {
                case "SUCCESS" :
                    component.set("v.shiftInProgress", true);
                    for (const toast of response.getReturnValue())
                        component.find("notifLib").showToast({
                            mode: toast.toastMode,
                            variant: toast.toastVariant,
                            message: toast.toastMessage
                        });
                    break;
            }
        });
        $A.enqueueAction(resetDatesAction);
    },
    
    handleHelpButton : function (component, event, helper) {
        component.set("v.helpSectionVisible", !component.get("v.helpSectionVisible"));
    }
});