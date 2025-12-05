CREATE OR REPLACE VIEW ProjectView AS
SELECT
    -- Project Details
    p.ProjectID,
    p.Title AS ProjectTitle,
    p.Description AS ProjectDescription,
    p.StartDate AS ProjectStartDate,
    p.Status AS ProjectStatus,
    -- Student Details
    s.StudentID,
    s.FullName AS StudentFullName,
    s.Email AS StudentEmail,
    -- Supervisor Details (for the project)
    sup.SupervisorID,
    sup.FullName AS SupervisorFullName,
    sup.Email AS SupervisorEmail,
    sup.Department AS SupervisorDepartment,
    -- Boolean indicating if the project has been evaluated or not
    CASE
        WHEN e.ProjectID IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS IsEvaluated,
    -- Evaluation Details (if evaluated, else NULL)
    e.grade AS ProjectGrade,
    e.comments AS ProjectFeedback,
    -- Supervisor Details (person who marked the project)
    mrk.SupervisorID AS MarkedBySupervisorID,
    mrk.FullName AS MarkedBySupervisorFullName,
    mrk.Email AS MarkedBySupervisorEmail
FROM
    Projects p
JOIN Students s ON p.StudentID = s.StudentID
JOIN Supervisors sup ON p.SupervisorID = sup.SupervisorID
-- Must be a left join since some projects may not have been evaluated yet
LEFT JOIN Evaluations e ON p.ProjectID = e.ProjectID
LEFT JOIN Supervisors mrk ON e.SupervisorID = mrk.SupervisorID;

COMMIT;
