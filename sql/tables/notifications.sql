CREATE TABLE Notifications (
    Notificationid VARCHAR2(5) PRIMARY KEY NOT NULL,
    Personid NUMBER NOT NULL,
    Message CLOB NOT NULL,
    Createdat TIMESTAMP DEFAULT SYSTIMESTAMP,
    Isread BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE Notifications IS 'Table to store notifications sent to students and supervisors regarding project evaluations.';
COMMENT ON COLUMN Notifications.Notificationid IS 'Unique identifier for each notification. This is in the format ps001 or fs002, where the first two letters indicate the type of notification and the numbers are sequential.';
COMMENT ON COLUMN Notifications.Personid IS 'References the ID of the person receiving the notification. This is the SupervisorID for supervisors and StudentID for students.';
COMMENT ON COLUMN Notifications.Message IS 'The content of the notification message sent to the person.';
COMMENT ON COLUMN Notifications.Createdat IS 'The timestamp when the notification was created.';
COMMENT ON COLUMN Notifications.Isread IS 'Indicates whether the notification has been read by the recipient.';
