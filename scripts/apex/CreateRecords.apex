//  Creates task and shipment test records in the scratch org.

Id me = UserInfo.getUserId();
DateTime nowTime = DateTime.now();
Date todayDate = Date.today();

List<Task> tasks = new List<Task>();
for (Integer i = 0; i < 1000; i++)
    tasks.add(new Task(
        OwnerId = me,
        ActivityDate = todayDate.addDays(Math.round(Math.random() * 14)),
        Subject = 'Task ' + i,
        Status = 'Not Started',
        Priority = 'Normal'
    ));
insert tasks;

List<Shipment> shipments = new List<Shipment>();
for (Integer i = 0; i < 8000; i++)
    shipments.add(new Shipment(
        ShipToName = 'John',
        ActualDeliveryDate = nowTime.addMinutes(-Math.round(Math.random() * 60 * 24 * 7 * 12)),
        Status = 'Delivered'
    ));
insert shipments;