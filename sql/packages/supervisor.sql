CREATE OR REPLACE PACKAGE supervisor AS
    PROCEDURE evaluate_project(project_id IN NUMBER, mark IN NUMBER, supervisor_id IN NUMBER, comments IN VARCHAR2);
    FUNCTION calculate_grade(mark IN NUMBER) RETURN CHAR;
    FUNCTION calculate_pass_fail(grade IN CHAR) RETURN VARCHAR2;
    PROCEDURE create_student_report(student_id IN NUMBER, report_name OUT VARCHAR2);
    PROCEDURE remark_project(project_id IN NUMBER, new_mark IN NUMBER, supervisor_id IN NUMBER, comments IN VARCHAR2);
    PROCEDURE view_project_ready_for_evaluation(subject IN VARCHAR2);
    PROCEDURE get_supervisor_notifications(supervisor_id IN NUMBER);
END supervisor;
/

CREATE OR REPLACE PACKAGE BODY supervisor AS -- noqa: PRS
    -- Procedure to evaluate a project
    -- Inserts evaluation record into Evaluations table
    -- Rolls back if insertion fails
    PROCEDURE evaluate_project(project_id IN NUMBER, mark IN NUMBER, supervisor_id IN NUMBER, comments IN VARCHAR2) IS
        next_evaluation_id NUMBER;
        project projects%ROWTYPE;
        CURSOR supervisor_cursor IS
            SELECT SupervisorID, Fullname FROM supervisors WHERE SupervisorID = supervisor_id;
        supervisor supervisor_cursor%ROWTYPE;
        supervisor_count NUMBER := 0;
        evaluations_before NUMBER;
        evaluations_after NUMBER;
        missing_field VARCHAR2(100);
        project_exists NUMBER;
        already_evaluated_count NUMBER := 0;
        duplicate_supervisor EXCEPTION;
        failed_to_get_evaluation_id EXCEPTION;
        already_evaluated EXCEPTION;
    BEGIN
        -- Check if project exists
        SELECT COUNT(*) INTO project_exists FROM projects WHERE ProjectID = project_id;
        missing_field := 'Project'; -- For error message
        IF project_exists = 0 THEN
            RAISE NO_DATA_FOUND;
        ELSE 
            DBMS_OUTPUT.PUT_LINE('Project exists: ' || project_exists);
        END IF;

        -- Check if supervisor exists
        OPEN supervisor_cursor;
        LOOP
            FETCH supervisor_cursor INTO supervisor;
            EXIT WHEN supervisor_cursor%NOTFOUND;
            supervisor_count := supervisor_count + 1;
        END LOOP;

        IF supervisor_count = 0 THEN
            missing_field := 'Supervisor'; -- For error message
            RAISE NO_DATA_FOUND;
        ELSIF supervisor_count > 1 THEN
            RAISE duplicate_supervisor; -- This will never happen if SupervisorID is unique
        ELSE
            DBMS_OUTPUT.PUT_LINE('Supervisor found: ' || supervisor.Fullname);
        END IF;
        CLOSE supervisor_cursor;

        -- Check that the supervisor hasn't already evaluated this project
        SELECT COUNT(*) INTO already_evaluated_count FROM Evaluations
        WHERE ProjectID = project_id AND SupervisorID = supervisor_id;

        if already_evaluated_count > 0 THEN
            RAISE already_evaluated;
        END IF;

        -- Get the number of evaluations before insertion
        SELECT COUNT(*) INTO evaluations_before FROM Evaluations;

        -- Create savepoint before insertion
        -- We can roll back to this point if insertion fails
        SAVEPOINT before_insertion;

        -- Output before insertion
        DBMS_OUTPUT.PUT_LINE('Inserting evaluation for ProjectID: ' || project_id || ', SupervisorID: ' || supervisor_id || ', Mark: ' || mark);

        -- Get the next evaluation ID
        SELECT NVL(MAX(EvaluationID), 0) + 1 INTO next_evaluation_id FROM Evaluations;

        -- Check if next_evaluation_id was retrieved successfully
        -- If not, raise an exception
        IF next_evaluation_id IS NULL THEN
            RAISE failed_to_get_evaluation_id;
        END IF;

        -- Update project with mark and supervisor ID
        INSERT INTO Evaluations (EvaluationID, ProjectID, SupervisorID, Grade, Comments)
        VALUES (next_evaluation_id, project_id, supervisor_id, calculate_grade(mark), comments);

        -- Get the number of evaluations after insertion
        SELECT COUNT(*) INTO evaluations_after FROM Evaluations;

        -- Check if insertion was successful
        IF evaluations_after = evaluations_before THEN
            -- Insertion failed
            ROLLBACK TO before_insertion;
            RAISE_APPLICATION_ERROR(-20004, 'Failed to insert evaluation record.');
        ELSE
            -- Insertion successful
            -- Commit + Log the successful insertion
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Evaluation recorded successfully. Please check your notifications for a receipt.');
        END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003, missing_field || ' not found.');
            WHEN duplicate_supervisor THEN
                RAISE_APPLICATION_ERROR(-20005, 'Duplicate supervisor found.'); -- This should never happen if SupervisorID is unique
            WHEN failed_to_get_evaluation_id THEN
                RAISE_APPLICATION_ERROR(-20006, 'Failed to get next evaluation ID.');
            WHEN already_evaluated THEN
                RAISE_APPLICATION_ERROR(-20008, 'This project has already been evaluated by this supervisor. Please use the remark procedure if you wish to change the evaluation.');
    END evaluate_project;

    -- Function to calculate grade based on mark
    -- Marks should be between 0 and 100
    -- Returns 'A', 'B', 'C', 'D', or 'F'
    FUNCTION calculate_grade(mark IN NUMBER) RETURN CHAR IS
        grade CHAR(1);
        invalid_mark EXCEPTION;
    BEGIN
        IF mark < 0 OR mark > 100 THEN
            RAISE invalid_mark;
        END IF;

        IF mark >= 90 THEN
            grade := 'A';
        ELSIF mark >= 80 THEN
            grade := 'B';
        ELSIF mark >= 70 THEN
            grade := 'C';
        ELSIF mark >= 60 THEN
            grade := 'D';
        ELSE
            grade := 'F';
        END IF;
        RETURN grade;

    EXCEPTION
        WHEN invalid_mark THEN
            RAISE_APPLICATION_ERROR(-20001, 'Mark must be between 0 and 100.');
    END calculate_grade;

    -- Function to calculate pass/fail based on grade
    -- Returns 'Pass' for grades A, B, C and 'Fail' for grades D, F
    FUNCTION calculate_pass_fail(grade IN CHAR) RETURN VARCHAR2 IS
        result VARCHAR2(10);
        invalid_grade EXCEPTION;
    BEGIN
        CASE grade
            WHEN 'A' THEN result := 'Pass';
            WHEN 'B' THEN result := 'Pass';
            WHEN 'C' THEN result := 'Pass';
            WHEN 'D' THEN result := 'Fail';
            WHEN 'F' THEN result := 'Fail';
            ELSE RAISE invalid_grade;
        END CASE;
        RETURN result;

    EXCEPTION
        WHEN invalid_grade THEN
            RAISE_APPLICATION_ERROR(-20002, 'Invalid grade provided.');
    END calculate_pass_fail;

    -- Procedure to create a student report
    -- Generates a report table for the given student ID
    -- The report includes count of each grade, most frequent grade, and average grade
    PROCEDURE create_student_report(student_id IN NUMBER, report_name OUT VARCHAR2) IS
        student_exists NUMBER;
        table_name CONSTANT VARCHAR2(50) := 'student_report_' || student_id || '_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
        student_not_found EXCEPTION;
    BEGIN
        -- Check if student exists
        SELECT COUNT(*) INTO student_exists FROM students WHERE StudentID = student_id;
        IF student_exists = 0 THEN
            RAISE student_not_found;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Student Found');
            DBMS_OUTPUT.PUT_LINE('Generating report for StudentID: ' || student_id);
        END IF;

        -- Dynamic SQL to create a report table for the student
        EXECUTE IMMEDIATE 'CREATE TABLE ' || table_name || ' AS
            SELECT ''student_details'' AS type, CAST(''StudentID: '' || ' || student_id || ' AS VARCHAR2(100)) AS item, ''Report for '' || FullName AS comments, 1 AS sort_order
            FROM students
            WHERE StudentID = ' || student_id || '

            UNION ALL

            SELECT ''total_projects'' AS type, CAST(COUNT(*) AS VARCHAR2(100)) AS item, ''Total number of projects for the student.'' AS comments, 2 AS sort_order
            FROM projects
            WHERE StudentID = ' || student_id || '

            UNION ALL

            -- We only count distinct projects that have been evaluated
            -- This prevents double counting if multiple evaluations exist for the same project (i.e. resits)
            SELECT ''total_projects_evaluated'' AS type, CAST(COUNT(ProjectID) AS VARCHAR2(100)) AS item, ''Total number of evaluations for the student.'' AS comments, 3 AS sort_order
            FROM (
                SELECT DISTINCT p.ProjectID
                FROM projects p
                JOIN Evaluations e ON p.ProjectID = e.ProjectID
                WHERE p.StudentID = ' || student_id || '
            )

            UNION ALL

            SELECT ''total_projects_pending'' AS type, CAST(COUNT(*) AS VARCHAR2(100)) AS item, ''Total number of evaluations pending for the student.'' AS comments, 4 AS sort_order
            FROM projects p
            LEFT JOIN Evaluations e ON p.ProjectID = e.ProjectID
            WHERE p.StudentID = ' || student_id || ' AND e.EvaluationID IS NULL

            UNION ALL

            SELECT ''grade_count'' AS type, CAST(grade AS VARCHAR2(100)) AS item, ''Count of evaluations with this grade: '' || cnt AS comments, 5 AS sort_order
            FROM (
                SELECT e.Grade AS grade, COUNT(*) AS cnt
                FROM projects p
                JOIN Evaluations e ON p.ProjectID = e.ProjectID
                WHERE p.StudentID = ' || student_id || '
                GROUP BY e.Grade
            )

            UNION ALL

            SELECT ''most_frequent_grade'' AS type, CAST(grade AS VARCHAR2(100)) AS item, ''Number of instances with this grade: '' || cnt AS comments, 6 AS sort_order
            FROM (
                SELECT e.Grade AS grade, COUNT(*) AS cnt
                FROM projects p
                JOIN Evaluations e ON p.ProjectID = e.ProjectID
                WHERE p.StudentID = ' || student_id || '
                GROUP BY e.Grade
                ORDER BY cnt DESC
                FETCH FIRST 1 ROWS ONLY
            )

            UNION ALL

            SELECT ''average_grade'' as type, CAST(supervisor.calculate_grade(average_mark) AS VARCHAR2(100)) AS item, ''Average mark calculated from all evaluations: '' || ROUND(average_mark, 2) AS comments, 7 AS sort_order
            FROM (
                SELECT SUM(
                    CASE e.Grade
                        WHEN ''A'' THEN 95
                        WHEN ''B'' THEN 85
                        WHEN ''C'' THEN 75
                        WHEN ''D'' THEN 65
                        WHEN ''F'' THEN 50
                    END
                ) / COUNT(*) AS average_mark
                FROM projects p
                JOIN Evaluations e ON p.ProjectID = e.ProjectID
                WHERE p.StudentID = ' || student_id || '
                GROUP BY p.StudentID
            )
            ORDER BY sort_order, type, item';

        DBMS_OUTPUT.PUT_LINE('Report table created: ' || table_name);

        report_name := table_name;

    EXCEPTION
        WHEN student_not_found THEN
            RAISE_APPLICATION_ERROR(-20007, 'Student with ID ' || student_id || ' not found.');

    END create_student_report;

    -- Procedure to remark a project
    -- Updates existing evaluation record in Evaluations table
    -- Rolls back if update fails
    PROCEDURE remark_project(project_id IN NUMBER, new_mark IN NUMBER, supervisor_id IN NUMBER, comments IN VARCHAR2) IS
    evaluation_not_found EXCEPTION;
    evaluation_integrity_error EXCEPTION;
    BEGIN
        -- Make a savepoint before update
        SAVEPOINT before_remark;

        -- Find and update the existing evaluation
        UPDATE Evaluations
        SET Grade = calculate_grade(new_mark),
            Comments = comments || ' (Remarked)'
        WHERE ProjectID = project_id AND SupervisorID = supervisor_id;

        IF SQL%NOTFOUND THEN
            ROLLBACK TO before_remark;
            RAISE evaluation_not_found;
        ELSIF SQL%ROWCOUNT > 1 THEN
            ROLLBACK TO before_remark;
            RAISE evaluation_integrity_error;
        ELSE
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Project remarked successfully.');
        END IF;

    EXCEPTION
        WHEN evaluation_not_found THEN
            RAISE_APPLICATION_ERROR(-20009, 'No existing evaluation found for this project by the specified supervisor. Please use the evaluate_project procedure to create a new evaluation.');
        WHEN evaluation_integrity_error THEN
            RAISE_APPLICATION_ERROR(-20012, 'Data integrity error: Multiple evaluations found for the same project by the same supervisor.');
    END remark_project;

    -- Procedure to view projects ready for evaluation
    -- Fetches projects that are completed but not yet evaluated for the given subject
    -- Outputs project details to DBMS_OUTPUT
    PROCEDURE view_project_ready_for_evaluation(subject IN VARCHAR2) IS
    CURSOR project_cursor IS
        SELECT p.ProjectID, p.StudentID, p.Title, p.Status
        FROM projects p
        JOIN Supervisors s ON p.SupervisorID = s.SupervisorID
        LEFT JOIN Evaluations e ON p.ProjectID = e.ProjectID
        WHERE e.EvaluationID IS NULL AND p.Status = 'Completed' AND s.Department = subject;
    
    -- you would normally just use %ROWTYPE alongside the cursor here
    -- but to illustrate user defined records, we define them manually
    TYPE project_row IS RECORD (
        ProjectID projects.ProjectID%TYPE,
        StudentID projects.StudentID%TYPE,
        Title projects.Title%TYPE,
        Status projects.Status%TYPE
    );

    -- Use a nested table to hold multiple records
    -- We use a nested table because it can be extended dynamically (unlike VARRAY which has a fixed size)
    TYPE project_table IS TABLE OF project_row;
    project_records project_table;

    current_row project_row;
    loop_counter NUMBER := 0;

    TYPE subject_list IS TABLE OF VARCHAR2(100);
    valid_subjects subject_list;

    invalid_subject EXCEPTION;
    BEGIN
        -- Check that the inputted subject is valid
        -- Get distinct departments from Supervisors table
        SELECT DISTINCT Department BULK COLLECT INTO valid_subjects FROM Supervisors;

        FOR i IN 1 .. valid_subjects.COUNT LOOP
            IF valid_subjects(i) = subject THEN
                DBMS_OUTPUT.PUT_LINE('Valid subject: ' || subject);
                EXIT;
            END IF;
            IF i = valid_subjects.COUNT THEN
                RAISE invalid_subject;
            END IF;
        END LOOP;

        -- Add the project ready for evaluation records to the nested table
        OPEN project_cursor;
        LOOP
            FETCH project_cursor BULK COLLECT INTO project_records LIMIT 100;
            EXIT WHEN project_cursor%NOTFOUND;
        END LOOP;
        CLOSE project_cursor;

        -- Check that there are projects to display
        IF project_records.COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No projects ready for evaluation in subject: ' || subject);
            RETURN;
        END IF;

        -- Output header
        DBMS_OUTPUT.PUT_LINE('There are ' || project_records.COUNT || ' projects ready for evaluation in subject: ' || subject);
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------');

        -- Output the projects
        WHILE loop_counter < project_records.COUNT LOOP
            -- Get the current record
            current_row := project_records(loop_counter + 1);

            DBMS_OUTPUT.PUT_LINE('ProjectID: ' || current_row.ProjectID || ', StudentID: ' || current_row.StudentID || ', Title: ' || current_row.Title || ', Status: ' || current_row.Status);

            loop_counter := loop_counter + 1;
        END LOOP;

    EXCEPTION
        WHEN invalid_subject THEN
            RAISE_APPLICATION_ERROR(-20010, 'Invalid subject provided. Please provide a valid subject.');

    END view_project_ready_for_evaluation;

    -- Procedure to get supervisor notifications
    -- Fetches unread notifications for the given supervisor ID
    -- Supervisor notifications have NotificationID starting with 'rc'
    -- Each notification is marked as read after being processed
    -- Notifications are instances of NotificationObj
    -- Notifications are output to DBMS_OUTPUT
    PROCEDURE get_supervisor_notifications(supervisor_id IN NUMBER) IS
    supervisor_name supervisors.Fullname%TYPE := NULL;

    -- Create a notification cursor to fetch unread supervisor notifications
    -- Supervisor notifications have a type of rc (first 2 characters of NotificationID)
    CURSOR notification_cursor IS
        SELECT NotificationID, Message, CreatedAt, IsRead
        FROM Notifications
        WHERE NotificationID LIKE 'rc%' AND PersonID = supervisor_id AND IsRead = 0;

    NotificationID Notifications.NotificationID%TYPE;
    Message Notifications.Message%TYPE;
    CreatedAt Notifications.CreatedAt%TYPE;
    IsRead Notifications.IsRead%TYPE;

    notification NotificationObj;
    notification_count NUMBER := 0;

    invalid_supervisor EXCEPTION;
    BEGIN

        -- Get supervisor name
        -- This will also serve to validate that the supervisor exists
        SELECT Fullname INTO supervisor_name FROM Supervisors WHERE SupervisorID = supervisor_id;

        -- Open the notification cursor
        OPEN notification_cursor;

        -- Iterate through the notification records and store them in the nested table
        -- Each nested table element is an instance of the NotificationObj object
        LOOP
            FETCH notification_cursor INTO NotificationID, Message, CreatedAt, IsRead;
            EXIT WHEN notification_cursor%NOTFOUND;
            notification_count := notification_count + 1;

            -- make a notification object
            notification := NotificationObj(
                NotificationID,
                Message,
                CreatedAt,
                IsRead
            );

            -- Output the notification details
            dBMS_OUTPUT.PUT_LINE('-- Notification Details --');
            DBMS_OUTPUT.PUT_LINE('NotificationID: ' || notification.NotificationID);
            DBMS_OUTPUT.PUT_LINE('CreatedAt: ' || TO_CHAR(notification.CreatedAt, 'YYYY-MM-DD HH24:MI:SS'));
            DBMS_OUTPUT.PUT_LINE('IsRead: ' || notification.IsRead);
            DBMS_OUTPUT.PUT_LINE('-- Notification Message --');
            DBMS_OUTPUT.PUT_LINE('Message: ' || notification.Message);
            DBMS_OUTPUT.PUT_LINE('-------------------------');

            -- Mark notification as read
            DBMS_OUTPUT.PUT_LINE('Marking notification ' || notification.NotificationID || ' as read.');
            notification.mark_as_read();
        END LOOP;

        if notification_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No new notifications for supervisor: ' || supervisor_name);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total notifications processed for supervisor ' || supervisor_name || ': ' || notification_count);
        END IF;

        -- Once the loop is done, close the cursor
        -- We can now work with the notifications collection
        CLOSE notification_cursor;

    EXCEPTION
        WHEN invalid_supervisor THEN
            RAISE_APPLICATION_ERROR(-20011, 'Supervisor with ID ' || supervisor_id || ' not found.');

    END get_supervisor_notifications;

END supervisor;
/