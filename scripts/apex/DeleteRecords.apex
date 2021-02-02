//  Deletes test records in org

delete [SELECT Id FROM Task];
delete [SELECT Id FROM Shipment];