CREATE TABLE Projects (
    Projectid NUMBER PRIMARY KEY,
    Title VARCHAR2(150) NOT NULL,
    Description CLOB,
    Studentid NUMBER NOT NULL,
    Supervisorid NUMBER NOT NULL,
    Startdate DATE DEFAULT SYSDATE,
    Status VARCHAR2(20) CHECK (Status IN ('Proposed', 'In Progress', 'Completed')),
    FOREIGN KEY (Studentid) REFERENCES Students (Studentid),
    FOREIGN KEY (Supervisorid) REFERENCES Supervisors (Supervisorid)
);
