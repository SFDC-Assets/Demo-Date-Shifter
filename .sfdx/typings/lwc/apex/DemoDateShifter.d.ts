declare module "@salesforce/apex/DemoDateShifter.getOrgObjectList" {
  export default function getOrgObjectList(): Promise<any>;
}
declare module "@salesforce/apex/DemoDateShifter.getDateTimeFields" {
  export default function getDateTimeFields(param: {objectApiName: any}): Promise<any>;
}
declare module "@salesforce/apex/DemoDateShifter.getObjectItems" {
  export default function getObjectItems(): Promise<any>;
}
declare module "@salesforce/apex/DemoDateShifter.getMinutesToShift" {
  export default function getMinutesToShift(param: {dateOfDemo: any, condition: any}): Promise<any>;
}
declare module "@salesforce/apex/DemoDateShifter.dateShift" {
  export default function dateShift(param: {dateOfDemo: any, condition: any}): Promise<any>;
}
