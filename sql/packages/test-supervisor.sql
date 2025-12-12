CREATE OR REPLACE PACKAGE TEST_SUPERVISOR AS
    -- Package to implement unit tests for the Supervisor Package

    -- Type to hold a collection of test cases (Nested Table)
    TYPE TESTCASE_TABLE IS TABLE OF TESTCASE;

    -- Type to hold associative array of test cases (Key value pairs)
    TYPE TESTCASE_TABLE_ARRAY IS TABLE OF TESTCASE_TABLE INDEX BY VARCHAR2(100);

    PROCEDURE RUN_TESTS;

END TEST_SUPERVISOR;
/

CREATE OR REPLACE PACKAGE BODY test_supervisor AS -- noqa: PRS

    -- Helper procedure to add and evaluate a test case to the test case table
    PROCEDURE add_testcase(
        p_testcase testcase,
        p_evaluation_type VARCHAR2,
        testcases IN OUT testcase_table
    ) IS
    BEGIN
        testcases.EXTEND;
        testcases(testcases.COUNT) := p_testcase;
        testcases(testcases.COUNT).evaluate_test(p_evaluation_type);
    END ADD_TESTCASE;


    -- 1. calculate_grade tests

    -- a. Valid marks
    PROCEDURE test_calculate_grade_valid(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
        v_evaluation_type VARCHAR2(20);

        TYPE grade_to_mark_table IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
        grade_to_mark grade_to_mark_table;
        grade VARCHAR2(1);
    BEGIN
        -- Add expected marks and grades to index by table
        -- This makes a set of key value pairs which align to expected outputs
        grade_to_mark('A') := 95;
        grade_to_mark('B') := 85;
        grade_to_mark('C') := 75;
        grade_to_mark('D') := 65;
        grade_to_mark('F') := 50;

        grade := grade_to_mark.FIRST;

        WHILE grade IS NOT NULL LOOP
            v_testcase := TESTCASE(
                testname => 'Test valid marks',
                description => 'Test calculate_grade for mark ' || grade_to_mark(grade) || '.',
                expectedoutput => grade,
                actualoutput => supervisor.calculate_grade(grade_to_mark(grade)),
                passed => 0
            );

            v_evaluation_type := 'strict';
            add_testcase(v_testcase, v_evaluation_type, testcases);

            grade := grade_to_mark.NEXT(grade);
        END LOOP;
    END TEST_CALCULATE_GRADE_VALID;

    -- b. Invalid marks (below 0)
    PROCEDURE test_calculate_grade_low(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
        grade CHAR(1);
    BEGIN
        BEGIN
            grade := supervisor.calculate_grade(-5);

        -- calculate_grade should raise an exception for invalid input
        -- We need to catch this and check that the exception message is as expected
        EXCEPTION
            WHEN OTHERS THEN
                v_testcase := TESTCASE(
                    testname => 'Test invalid low mark',
                    description => 'Test calculate_grade with invalid mark -5.',
                    expectedoutput => 'Mark must be between 0 and 100.',
                    actualoutput => SQLERRM,
                    passed => 0
                );

            add_testcase(v_testcase, 'generic', testcases);
        END;
    END TEST_CALCULATE_GRADE_LOW;

    -- c. Invalid marks (above 100)
    PROCEDURE test_calculate_grade_high(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
        grade CHAR(1);
    BEGIN
        BEGIN
            grade := supervisor.calculate_grade(105);

        -- calculate_grade should raise an exception for invalid input
        -- We need to catch this and check that the exception message is as expected
        EXCEPTION
            WHEN OTHERS THEN
                v_testcase := TESTCASE(
                    testname => 'Test invalid high mark',
                    description => 'Test calculate_grade with invalid mark 105.',
                    expectedoutput => 'Mark must be between 0 and 100.',
                    actualoutput => SQLERRM,
                    passed => 0
                );

            add_testcase(v_testcase, 'generic', testcases);
        END;
    END TEST_CALCULATE_GRADE_HIGH;

    -- Master procedure to run all calculate_grade tests
    PROCEDURE test_calculate_grade(
        testcases IN OUT testcase_table
    ) IS
    BEGIN
        test_calculate_grade_valid(testcases);
        test_calculate_grade_low(testcases);
        test_calculate_grade_high(testcases);
    END TEST_CALCULATE_GRADE;


    -- 2. evaluate_project tests

    -- a. Valid evaluation
    procedure test_evaluate_project_valid(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
        v_rows_before NUMBER;
        v_rows_after NUMBER;
        v_num_lines NUMBER := 10;
        v_console_output DBMS_OUTPUT.CHARARR;
        v_success_message VARCHAR2(4000);
    BEGIN
        -- Remove any existing validations for a clean test environment
        DELETE FROM evaluations WHERE projectid = 1 AND supervisorid = 1;

        -- Count rows before evaluation
        SELECT COUNT(*) INTO v_rows_before FROM evaluations;

        -- Perform valid evaluation
        supervisor.evaluate_project(
            project_id => 1,
            supervisor_id => 1,
            mark => 85,
            comments => 'Good work'
        );

        -- Count rows after evaluation
        SELECT COUNT(*) INTO v_rows_after FROM evaluations;

        -- Test that one row has been added
        v_testcase := TESTCASE(
            testname => 'Test valid project evaluation',
            description => 'Test evaluate_project with valid inputs. This should add one row to evaluations.',
            expectedoutput => TO_CHAR(v_rows_before + 1),
            actualoutput => TO_CHAR(v_rows_after),
            passed => 0
        );

        add_testcase(v_testcase, 'strict', testcases);

        -- Get the console output for further testing
        DBMS_OUTPUT.GET_LINES(LINES => v_console_output, NUMLINES => v_num_lines);

        -- The success message should be the last but one line of console output
        -- The last line is usually blank
        v_success_message := v_console_output(v_console_output.COUNT - 1);

        -- Test that a success message is returned
        v_testcase := TESTCASE(
            testname => 'Test valid project evaluation message',
            description => 'Test evaluate_project returns success message for valid inputs.',
            expectedoutput => 'Evaluation recorded successfully. Please check your notifications for a receipt.',
            actualoutput => v_success_message,
            passed => 0
        );

        add_testcase(v_testcase, 'strict', testcases);

        -- Cleanup after test
        DELETE FROM evaluations WHERE projectid = 1 AND supervisorid = 1;
    END TEST_EVALUATE_PROJECT_VALID;

    -- b. Invalid supervisor
    PROCEDURE test_evaluate_project_invalid_supervisor(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
    BEGIN
        -- Test with an invalid supervisor ID
        supervisor.evaluate_project(
            project_id => 1,
            supervisor_id => 999, -- Invalid supervisor ID
            mark => 85,
            comments => 'Good work'
        );

    EXCEPTION
        WHEN OTHERS THEN
            -- Check the output
            v_testcase := TESTCASE(
                testname => 'Test invalid supervisor ID',
                description => 'Test evaluate_project with an invalid supervisor ID.',
                expectedoutput => 'Supervisor not found',
                actualoutput => SQLERRM,
                passed => 0
            );

        add_testcase(v_testcase, 'generic', testcases);
    END TEST_EVALUATE_PROJECT_INVALID_SUPERVISOR;

    -- c. Invalid project
    PROCEDURE test_evaluate_project_invalid_project(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
    BEGIN
        -- Test with an invalid project ID
        supervisor.evaluate_project(
            project_id => 999, -- Invalid project ID
            supervisor_id => 1,
            mark => 85,
            comments => 'Good work'
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Check the output
            v_testcase := TESTCASE(
                testname => 'Test invalid project ID',
                description => 'Test evaluate_project with an invalid project ID.',
                expectedoutput => 'Project not found',
                actualoutput => SQLERRM,
                passed => 0
            );
        add_testcase(v_testcase, 'generic', testcases);
    END TEST_EVALUATE_PROJECT_INVALID_PROJECT;

    -- d. Invalid mark
    PROCEDURE test_evaluate_project_invalid_mark(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
    BEGIN
        -- Test with an invalid mark
        supervisor.evaluate_project(
            project_id => 1,
            supervisor_id => 1,
            mark => 110, -- Invalid mark
            comments => 'Good work'
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Check the output
            v_testcase := TESTCASE(
                testname => 'Test invalid mark',
                description => 'Test evaluate_project with an invalid mark.',
                expectedoutput => 'Mark must be between 0 and 100',
                actualoutput => SQLERRM,
                passed => 0
            );

        add_testcase(v_testcase, 'generic', testcases);
    END TEST_EVALUATE_PROJECT_INVALID_MARK;

    -- e. Duplicate evaluation
    PROCEDURE test_evaluate_project_duplicate_evaluation(
        testcases IN OUT testcase_table
    ) IS
        v_testcase TESTCASE;
    BEGIN
        -- Remove any existing validations for a clean test environment
        DELETE FROM evaluations WHERE projectid = 1 AND supervisorid = 1;

        -- First, perform a valid evaluation
        supervisor.evaluate_project(
            project_id => 1,
            supervisor_id => 1,
            mark => 85,
            comments => 'Good work'
        );

        -- Now, attempt to perform a duplicate evaluation
        supervisor.evaluate_project(
            project_id => 1,
            supervisor_id => 1,
            mark => 90,
            comments => 'Updated work'
        );

    EXCEPTION
        WHEN OTHERS THEN
            -- Check the output
            v_testcase := TESTCASE(
                testname => 'Test duplicate evaluation',
                description => 'Test evaluate_project with a duplicate evaluation attempt.',
                expectedoutput => 'This project has already been evaluated by this supervisor. Please use the remark procedure if you wish to change the evaluation',
                actualoutput => SQLERRM,
                passed => 0
            );
        add_testcase(v_testcase, 'generic', testcases);

        -- Cleanup after test
        DELETE FROM evaluations WHERE projectid = 1 AND supervisorid = 1;
    END TEST_EVALUATE_PROJECT_DUPLICATE_EVALUATION;

    -- Master procedure to run all evaluate_project tests
    PROCEDURE test_evaluate_project(
        testcases IN OUT testcase_table
    ) IS
    BEGIN
        test_evaluate_project_valid(testcases);
        test_evaluate_project_invalid_supervisor(testcases);
        test_evaluate_project_invalid_project(testcases);
        test_evaluate_project_invalid_mark(testcases);
        test_evaluate_project_duplicate_evaluation(testcases);
    END TEST_EVALUATE_PROJECT;


    -- TODO: Implement tests for other procedures in the supervisor package
    -- This is out of scope for the coursework assignment

    -- Main procedure to run all tests in the package


    PROCEDURE run_tests IS
        testcases_array testcase_table_array;
        testcase_key VARCHAR2(100);
        passed_count NUMBER := 0;
    BEGIN
        -- Initialize test case arrays for each area of testing
        testcases_array('calculate_grade') := testcase_table();
        testcases_array('evaluate_project') := testcase_table();

        -- Run the procedure-specific test suites
        -- These will initialise each test case into the respective test case arrays
        test_calculate_grade(testcases_array('calculate_grade'));
        test_evaluate_project(testcases_array('evaluate_project'));

        -- Output results
        testcase_key := testcases_array.FIRST;

        -- Clear the DBMS_OUTPUT buffer before starting
        DBMS_OUTPUT.DISABLE;
        DBMS_OUTPUT.ENABLE;

        WHILE testcase_key IS NOT NULL LOOP
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
            DBMS_OUTPUT.PUT_LINE('Running ' || testcases_array(testcase_key).COUNT || ' tests for: ' || testcase_key);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');

            FOR i IN 1 .. testcases_array(testcase_key).COUNT LOOP
                testcases_array(testcase_key)(i).output_result;

                IF testcases_array(testcase_key)(i).passed = 1 THEN
                    passed_count := passed_count + 1;
                END IF;
            END LOOP;

            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
            DBMS_OUTPUT.PUT_LINE('Summary for ' || testcase_key || ': ' || passed_count || ' out of ' || testcases_array(testcase_key).COUNT || ' tests passed.');
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');

            passed_count := 0;
            testcase_key := testcases_array.NEXT(testcase_key);
        END LOOP;
    END run_tests;
END test_supervisor;
/
