-- Creates an index on the Projects table to optimise queries filtering by StudentID and Status
CREATE INDEX idx_project_student_status ON projects (studentid, status);
