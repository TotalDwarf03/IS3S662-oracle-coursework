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
