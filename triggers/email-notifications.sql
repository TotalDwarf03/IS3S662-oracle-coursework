CREATE OR REPLACE TRIGGER email_notifications
AFTER INSERT OR UPDATE ON evaluations
FOR EACH ROW
DECLARE
    -- define message template collection to hold different notification messages
    TYPE template IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(2);
    message_template TEMPLATE;

    -- define 2 arrays for the pass and fail grades
    TYPE pass_grades_array IS VARRAY(3) OF CHAR(1);
    TYPE fail_grades_array IS VARRAY(2) OF CHAR(1);

    -- instantiate the arrays with the respective grades (these are constants)
    pass_grades PASS_GRADES_ARRAY := pass_grades_array('A', 'B', 'C');
    fail_grades FAIL_GRADES_ARRAY := fail_grades_array('D', 'F');

    -- make constants to hold array lengths
    pass_grade_len NUMBER := pass_grades.count;
    fail_grade_len NUMBER := fail_grades.count;

    project_result VARCHAR2(4);
    message_type VARCHAR2(2);

    -- Variables to hold additional information collected from other tables
    project_name projects.title % TYPE;
    supervisor_name supervisors.fullname % TYPE;
    student_id students.studentid % TYPE;

    -- Variables for the Student Notification Generation
    last_notification_id VARCHAR2(5);
    notification_message VARCHAR2(4000);

    -- Variables for the Supervisor Confirmation Notification
    last_notification_id_rc VARCHAR2(5);
    supervisor_notification_message VARCHAR2(4000);

BEGIN

    -- Define message templates
    message_template('ps') := 'Well done! Your recent project (PROJECTNAME) has been evaluated positively by (SUPERVISORNAME) and got a grade of (GRADE).';
    message_template('fs') := 'Attention needed! Your recent project (PROJECTNAME) has been evaluated negatively by (SUPERVISORNAME) and got a grade of (GRADE). This is a fail and requires you to retake the project.';
    message_template('rs') := 'Your recent project (PROJECTNAME) has been re-evaluated by (SUPERVISORNAME) and got a new grade of (GRADE) instead of (OLDGRADE).';
    message_template('rc') := 'Dear (SUPERVISORNAME), your evaluation for the project (PROJECTNAME) has been submitted successfully with a grade of (GRADE).';

    -- Figure out whether the project passed or failed

    -- Loop through pass grades in the array
    -- If a match is found, set project_result to 'pass' and exit loop
    FOR i IN 1..pass_grade_len LOOP
        IF: NEW.Grade = pass_grades(i) THEN
            project_result := 'pass';
            EXIT;
        END IF;
    END LOOP;

    -- If not found in pass grades, loop through fail grades
    -- If a match is found, set project_result to 'fail' and exit loop
    IF project_result IS NULL THEN
        FOR i IN 1..fail_grade_len LOOP
            IF: NEW.Grade = fail_grades(i) THEN
                project_result := 'fail';
                EXIT;
            END IF;
        END LOOP;
    END IF;

    -- Determine message type based on operation and grade
    IF INSERTING THEN
        IF project_result = 'pass' THEN
            message_type := 'ps';
        ELSE
            message_type := 'fs';
        END IF;
    ELSIF UPDATING THEN
        message_type := 'rs';
    END IF;

    -- Get the additional information needed for the message
    -- Project Name
    SELECT title INTO project_name FROM projects
    WHERE projectid =: NEW.ProjectID;

    -- Supervisor Name
    SELECT fullname INTO supervisor_name FROM supervisors
    WHERE supervisorid =: NEW.SupervisorID;

    -- Student ID
    SELECT studentid INTO student_id FROM projects
    WHERE projectid =: NEW.ProjectID;

    -- Create the notification message by replacing placeholders in the template
    -- Get the template for the determined message type (from collection)
    notification_message := message_template(message_type);
    -- Replace placeholders
    notification_message := replace(notification_message, '(PROJECTNAME)', project_name);
    notification_message := replace(notification_message, '(SUPERVISORNAME)', supervisor_name);
    notification_message := replace(notification_message, '(GRADE)', to_char(: NEW.Grade));
    -- If it's a re-score, also replace the (OLDGRADE) placeholder (this is only for 'rs' type)
    IF message_type = 'rs' THEN
        notification_message := replace(notification_message, '(OLDGRADE)', to_char(: OLD.Grade));
    END IF;

    -- Get the last NotificationID and increment it
    BEGIN
        SELECT notificationid INTO last_notification_id
        FROM notifications
        -- Filter to get only notifications of the same type
        -- i.e. 'ps%' to match 'ps001', 'ps002', etc.
        -- This means that each type has its own sequence, allowing more notifications to be stored
        WHERE notificationid LIKE message_type || '%'
        ORDER BY createdat DESC
        FETCH FIRST 1 ROW ONLY;

        -- Remove the prefix (first 2 characters) and increment the numeric part
        last_notification_id := to_char(to_number(substr(last_notification_id, 3)) + 1);
        EXCEPTION
        WHEN no_data_found THEN
        last_notification_id := '001';
        WHEN OTHERS THEN
        RAISE;
    END;

    -- Insert the notification into the Notifications table (Student)
    INSERT INTO notifications (notificationid, personid, message)
    VALUES (
        message_type || lpad(last_notification_id, 3, '0'),
        student_id,
        notification_message
    );

    -- Create the supervisor confirmation message
    supervisor_notification_message := message_template('rc');
    supervisor_notification_message := replace(supervisor_notification_message, '(PROJECTNAME)', project_name);
    supervisor_notification_message := replace(supervisor_notification_message, '(SUPERVISORNAME)', supervisor_name);
    supervisor_notification_message := replace(supervisor_notification_message, '(GRADE)', to_char(: NEW.Grade));

    -- Get the last NotificationID and increment it for supervisor notification
    BEGIN
        SELECT notificationid INTO last_notification_id_rc
        FROM notifications
        WHERE notificationid LIKE 'rc%'
        ORDER BY createdat DESC
        FETCH FIRST 1 ROW ONLY;

        -- Remove the prefix (first 2 characters) and increment the numeric part
        last_notification_id_rc := to_char(to_number(substr(last_notification_id_rc, 3)) + 1);
        EXCEPTION
        WHEN no_data_found THEN
        last_notification_id_rc := '001';
        WHEN OTHERS THEN
        RAISE;
    END;

    -- Insert the confirmation notification into the Notifications table (Supervisor)
    INSERT INTO notifications (notificationid, personid, message)
    VALUES (
        'rc' || lpad(last_notification_id_rc, 3, '0'),
        : NEW.SupervisorID,
        supervisor_notification_message
    );
END;
