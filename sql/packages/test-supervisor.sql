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
        v_actual_output VARCHAR2(4000);
        v_expected_output VARCHAR2(4000);
        v_testcase TESTCASE;
        v_evaluation_type VARCHAR2(20);

        TYPE grade_to_mark_table IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
        grade_to_mark grade_to_mark_table;
        grade VARCHAR2(1);
    BEGIN
        -- Test Case 1: Valid Marks
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


    -- 3. evaluate_project tests

    -- a. Valid evaluation


    -- b. Invalid supervisor


    -- c. Invalid project


    -- d. Invalid mark


    -- e. Duplicate evaluation



    -- 4. create_student_report tests

    -- a. Valid student


    -- b. Invalid student



    -- 5. remark_project tests

    -- a. Valid remark


    -- b. Invalid project


    -- c. Invalid supervisor


    -- d. No existing evaluation


    -- e. Invalid new mark


    -- f. Data integrity error (multiple evaluations)



    -- 6. view_project_ready_for_evaluation tests

    -- a. Valid subject with projects


    -- b. Valid subject with no projects


    -- c. Invalid subject



    -- 7. get_supervisor_notifications tests

    -- a. Valid supervisor with notifications


    -- b. Valid supervisor with no notifications


    -- c. Invalid supervisor



    -- Main procedure to run all tests in the package


    PROCEDURE run_tests IS
        testcases_array testcase_table_array;
        testcase_key VARCHAR2(100);
        passed_count NUMBER := 0;
    BEGIN
        testcases_array('calculate_grade') := testcase_table();

        test_calculate_grade(testcases_array('calculate_grade'));

        -- Output results
        testcase_key := testcases_array.FIRST;

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
