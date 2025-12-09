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
/

-- The head for this is defined in notification-obj-head.sql
CREATE OR REPLACE TYPE BODY NOTIFICATIONOBJ AS
    MEMBER PROCEDURE mark_as_read IS
    BEGIN
        SELF.ISREAD := 1;
        UPDATE NOTIFICATIONS
        SET ISREAD = 1
        WHERE NOTIFICATIONID = SELF.NOTIFICATIONID;

        IF SQL % ROWCOUNT = 0 THEN
            raise_application_error(-20001, 'Error marking notification as read.');
        END IF;

        DBMS_OUTPUT.PUT_LINE('Notification ' || SELF.NOTIFICATIONID || ' marked as read.');
    END MARK_AS_READ;
END;
/
