BEGIN
    RAISE_APPLICATION_ERROR(-20011, 'Data integrity error: Project not found or supervisor mismatch.');

    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error occurred while remarking project: ' || SQLERRM);
END;

DECLARE
    OUTPUT_LINES DBMS_OUTPUT.CHARARR;
    NUM_LINES INTEGER := 10;
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST');
    DBMS_OUTPUT.PUT_LINE('ANOTHER TEST LINE');
    DBMS_OUTPUT.GET_LINES(LINES => OUTPUT_LINES, NUMLINES => NUM_LINES);

    FOR I IN 1..OUTPUT_LINES.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Output Line ' || I || ': ' || OUTPUT_LINES(I));

        DBMS_OUTPUT.PUT_LINE('Is test? ' || (CASE WHEN OUTPUT_LINES(I) = 'TEST' THEN 'TRUE' ELSE 'FALSE' END));
    END LOOP;
END;

-- This confirms we can make a testing package for the existing supervisor package and trigger.
-- Since we can intercept the raised errors by catching them again, we can verify that errors are raised.
-- Additionally, when we log things with DBMS_OUTPUT.PUT_LINE, we can use DBMS_OUTPUT.GET_LINES to get the output and verify it.
