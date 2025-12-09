-- 1. evaluate_project tests

-- a. Valid evaluation
BEGIN
    supervisor.evaluate_project(
        project_id => 1,
        supervisor_id => 1,
        mark => 85,
        comments => 'Good work'
    );
END;

-- b. Invalid supervisor
BEGIN
    supervisor.evaluate_project(
        project_id => 1,
        supervisor_id => 999, -- Non-existent supervisor
        mark => 85,
        comments => 'Good work'
    );
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: No data found.
END;

-- c. Invalid project
BEGIN
    supervisor.evaluate_project(
        project_id => 999, -- Non-existent project
        supervisor_id => 1,
        mark => 85,
        comments => 'Good work'
    );
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: No data found.
END;

-- d. Invalid mark
BEGIN
    supervisor.evaluate_project(
        project_id => 1,
        supervisor_id => 1,
        mark => 150, -- Invalid mark
        comments => 'Good work'
    );
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Mark must be between 0 and 100.
END;

-- e. Duplicate evaluation
BEGIN
    supervisor.evaluate_project(
        project_id => 1,
        supervisor_id => 1,
        mark => 90,
        comments => 'Excellent work'
    );
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Evaluation already exists for this project and supervisor.
END;

-- 2. calculate_grade tests

-- a. Valid marks
DECLARE
    grade CHAR(1);
BEGIN
    grade := supervisor.calculate_grade(95);
    DBMS_OUTPUT.PUT_LINE('Grade for 95: ' || grade); -- Expected:
    grade := supervisor.calculate_grade(85);
    DBMS_OUTPUT.PUT_LINE('Grade for 85: ' || grade); -- Expected:
    grade := supervisor.calculate_grade(75);
    DBMS_OUTPUT.PUT_LINE('Grade for 75: ' || grade); -- Expected:
    grade := supervisor.calculate_grade(65);
    DBMS_OUTPUT.PUT_LINE('Grade for 65: ' || grade); -- Expected:
    grade := supervisor.calculate_grade(50);
    DBMS_OUTPUT.PUT_LINE('Grade for 50: ' || grade); -- Expected:
END;

-- b. Invalid marks
-- Below 0
DECLARE
    grade CHAR(1);
BEGIN
    grade := supervisor.calculate_grade(-5);
    DBMS_OUTPUT.PUT_LINE('Grade for -5: ' || grade);
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Mark must be between 0 and 100.
END;

-- Above 100
DECLARE
    grade CHAR(1);
BEGIN
    grade := supervisor.calculate_grade(105);
    DBMS_OUTPUT.PUT_LINE('Grade for 105: ' || grade);
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Mark must be between 0 and 100.
END;

-- 3. calculate_pass_fail tests

-- a. Valid grades
DECLARE
    result VARCHAR2(10);
BEGIN
    result := supervisor.calculate_pass_fail('A');
    DBMS_OUTPUT.PUT_LINE('Pass/Fail for A: ' || result); -- Expected:
    result := supervisor.calculate_pass_fail('B');
    DBMS_OUTPUT.PUT_LINE('Pass/Fail for B: ' || result); -- Expected:
    result := supervisor.calculate_pass_fail('C');
    DBMS_OUTPUT.PUT_LINE('Pass/Fail for C: ' || result); -- Expected:
    result := supervisor.calculate_pass_fail('D');
    DBMS_OUTPUT.PUT_LINE('Pass/Fail for D: ' || result); -- Expected:
    result := supervisor.calculate_pass_fail('F');
    DBMS_OUTPUT.PUT_LINE('Pass/Fail for F: ' || result); -- Expected:
END;

-- b. Invalid grade
DECLARE
    result VARCHAR2(10);
BEGIN
    result := supervisor.calculate_pass_fail('X');
    DBMS_OUTPUT.PUT_LINE('Pass/Fail for X: ' || result);
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Invalid grade provided.
END;

-- 4. create_student_report tests

-- a. Valid student
DECLARE
    report_name VARCHAR2(100);
BEGIN
    supervisor.create_student_report(1, report_name);
    DBMS_OUTPUT.PUT_LINE('Report created for StudentID 1: ' || report_name);
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm);
END;

-- b. Invalid student
DECLARE
    report_name VARCHAR2(100);
BEGIN
    supervisor.create_student_report(999, report_name); -- Non-existent student
    DBMS_OUTPUT.PUT_LINE('Report created for StudentID 999: ' || report_name);
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: No data found.
END;

-- 5. remark_project tests

-- a. Valid remark
BEGIN
    supervisor.remark_project(
        project_id => 1,
        new_mark => 90,
        supervisor_id => 1,
        comments => 'Re-evaluated, improved performance'
    );
    DBMS_OUTPUT.PUT_LINE('ProjectID 1 remarked successfully.');
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm);
END;

-- b. Invalid project
BEGIN
    supervisor.remark_project(
        project_id => 999, -- Non-existent project
        new_mark => 90,
        supervisor_id => 1,
        comments => 'Re-evaluated, improved performance'
    );
    DBMS_OUTPUT.PUT_LINE('ProjectID 999 remarked successfully.');
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Evaluation not found.
END;

-- c. Invalid supervisor
BEGIN
    supervisor.remark_project(
        project_id => 1,
        new_mark => 90,
        supervisor_id => 999, -- Non-existent supervisor
        comments => 'Re-evaluated, improved performance'
    );
    DBMS_OUTPUT.PUT_LINE('ProjectID 1 remarked by invalid supervisor successfully.');
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Evaluation not found.
END;

-- d. No existing evaluation
BEGIN
    supervisor.remark_project(
        project_id => 2, -- Assuming no evaluation exists for this project
        new_mark => 90,
        supervisor_id => 1,
        comments => 'Re-evaluated, improved performance'
    );
    DBMS_OUTPUT.PUT_LINE('ProjectID 2 remarked successfully.');
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm);
END;

-- e. Invalid new mark
BEGIN
    supervisor.remark_project(
        project_id => 1,
        new_mark => -5, -- Invalid mark
        supervisor_id => 1,
        comments => 'Re-evaluated, improved performance'
    );
    DBMS_OUTPUT.PUT_LINE('ProjectID 1 remarked successfully.');
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Invalid mark.
END;

-- 6. view_project_ready_for_evaluation tests

-- a. Valid subject with projects
BEGIN
    supervisor.view_project_ready_for_evaluation('Computer Science');
END;

-- b. Valid subject with no projects
BEGIN
    supervisor.view_project_ready_for_evaluation('History');
END;

-- c. Invalid subject
BEGIN
    supervisor.view_project_ready_for_evaluation('InvalidSubject');
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: Invalid subject provided.
END;

-- 7. get_supervisor_notifications tests

-- Note: Before running these tests, ensure that there are notifications in the database for testing.
-- To set these up, run supervisors.evaluate_project or remark_project as they generate notifications.
--
-- For example, run:
--
-- BEGIN
--     supervisor.evaluate_project(1, 1, 85, 'Good work');
-- END;
-- 
-- Or
-- 
-- BEGIN
--     supervisor.remark_project(1, 90, 1, 'Re-evaluated, improved performance');
-- END;

-- a. Valid supervisor with notifications
BEGIN
    supervisor.get_supervisor_notifications(1);
END;

-- b. Valid supervisor with no notifications
BEGIN
    supervisor.get_supervisor_notifications(2); -- Assuming SupervisorID 2 has no notifications
END;

-- c. Invalid supervisor
BEGIN
    supervisor.get_supervisor_notifications(999); -- Non-existent supervisor
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm); -- Expected: No data found.
END;
