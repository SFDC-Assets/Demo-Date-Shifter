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

List<Event> events = new List<Event>();
for (Integer i = 0; i < 8000; i++)
    events.add(new Event(
        OwnerId = me,
        Subject = 'Event ' + i,
        StartDateTime = nowTime.addMinutes(-Math.round(Math.random() * 60 * 24 * 7 * 12)),
        DurationInMinutes = 30
    ));
insert events;