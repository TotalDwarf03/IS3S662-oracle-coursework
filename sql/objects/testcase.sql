-- Create TestCase Object Type
-- This type is used within the testing package to represent individual test cases
CREATE OR REPLACE TYPE TESTCASE AS OBJECT (
    TESTNAME VARCHAR2(100),
    DESCRIPTION VARCHAR2(4000),
    EXPECTEDOUTPUT VARCHAR2(4000),
    ACTUALOUTPUT VARCHAR2(4000),
    PASSED NUMBER(1),
    MEMBER PROCEDURE evaluate_test(evaluation_type VARCHAR2),
    MEMBER PROCEDURE output_result
);
/

CREATE OR REPLACE TYPE BODY TESTCASE AS

    -- Assert whether the test case has passed based on the evaluation type
    -- evaluation_type can be 'strict', 'case_insensitive', or 'generic'
    MEMBER PROCEDURE evaluate_test(evaluation_type VARCHAR2) IS
    BEGIN
        -- Perform evaluation based on the specified type
        IF lower(EVALUATION_TYPE) = 'strict' THEN
            IF SELF.EXPECTEDOUTPUT = SELF.ACTUALOUTPUT THEN
                SELF.PASSED := 1;
            ELSE
                SELF.PASSED := 0;
            END IF;
        ELSIF lower(EVALUATION_TYPE) = 'case_insensitive' THEN
            IF lower(SELF.EXPECTEDOUTPUT) = lower(SELF.ACTUALOUTPUT) THEN
                SELF.PASSED := 1;
            ELSE
                SELF.PASSED := 0;
            END IF;
        ELSIF lower(EVALUATION_TYPE) = 'generic' THEN
            IF lower(SELF.ACTUALOUTPUT) LIKE '%' || lower(SELF.EXPECTEDOUTPUT) || '%' THEN
                SELF.PASSED := 1;
            ELSE
                SELF.PASSED := 0;
            END IF;
        ELSE
            -- The evaluation type is unsupported
            raise_application_error(-20002, 'Unsupported evaluation type: ' || EVALUATION_TYPE);
        END IF;
    END EVALUATE_TEST;

    -- Output the result of the test case
    MEMBER PROCEDURE output_result IS
    BEGIN
        IF SELF.PASSED = 1 THEN
            DBMS_OUTPUT.PUT_LINE(SELF.TESTNAME || ': ' || SELF.DESCRIPTION || '. (PASSED)');
        ELSE
            DBMS_OUTPUT.PUT_LINE(SELF.TESTNAME || ': ' || SELF.DESCRIPTION || '. (FAILED) | Expected: "' || SELF.EXPECTEDOUTPUT || '", Actual: "' || SELF.ACTUALOUTPUT || '".');
        END IF;
    END OUTPUT_RESULT;
END;
/
