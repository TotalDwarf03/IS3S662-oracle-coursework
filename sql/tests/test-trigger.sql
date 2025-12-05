-- 1. Test trigger when inserting a new evaluation

-- a. Passing grade (ps type notification)
INSERT INTO Evaluations (Evaluationid, Projectid, Supervisorid, Grade, Comments)
VALUES (
    (SELECT COALESCE(MAX(Evaluationid), 0) + 1 FROM Evaluations),
    1, 1, 'A', 'Excellent work!'
);
COMMIT;

-- b. Failing grade (fs type notification)
INSERT INTO Evaluations (Evaluationid, Projectid, Supervisorid, Grade, Comments)
VALUES (
    (SELECT COALESCE(MAX(Evaluationid), 0) + 1 FROM Evaluations),
    2, 2, 'D', 'Needs improvement.'
);
COMMIT;

-- 2. Test trigger when updating an evaluation (rs type notification)
UPDATE Evaluations
SET Grade = 'C', Comments = 'Re-evaluated to average performance.'
WHERE Evaluationid = 1;
COMMIT;
