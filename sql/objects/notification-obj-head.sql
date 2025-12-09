-- Create Notification object type
-- This type is used within get_supervisor_notifications procedure
-- The body for this is defined in notification-obj-body.sql
CREATE OR REPLACE TYPE NOTIFICATIONOBJ AS OBJECT (
    NOTIFICATIONID VARCHAR2(5),
    MESSAGE VARCHAR2(4000),
    CREATEDAT TIMESTAMP,
    ISREAD NUMBER(1),
    MEMBER PROCEDURE mark_as_read
);
