-- Creates an index on the notifications table to optimise queries filtering by PersonID and IsRead
CREATE INDEX idx_notif_person_isread ON notifications (personid, isread);
