declare module "@salesforce/apex/DemoShiftDates.getObjectItems" {
  export default function getObjectItems(): Promise<any>;
}
declare module "@salesforce/apex/DemoShiftDates.getMinutesToShift" {
  export default function getMinutesToShift(param: {dateOfDemo: any, condition: any}): Promise<any>;
}
declare module "@salesforce/apex/DemoShiftDates.dateShift" {
  export default function dateShift(param: {dateOfDemo: any, condition: any}): Promise<any>;
}
