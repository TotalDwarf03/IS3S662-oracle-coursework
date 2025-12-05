-- Creates an index on the notifications table to optimise queries filtering by PersonID and Status
CREATE INDEX idx_notif_person_status ON notifications (personid, status);
