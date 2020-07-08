//  Deletes test records in org

List<Task> tasks = [SELECT Id FROM Task];
delete tasks;

List<Shipment> shipments = [SELECT Id FROM Shipment];
delete shipments;