-- Creates an index on the Projects table to optimise queries filtering by SupervisorID and Status
CREATE INDEX idx_project_supervisor_status ON projects (supervisorid, status);
