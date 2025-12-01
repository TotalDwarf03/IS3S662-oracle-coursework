CREATE TABLE Evaluations (
    Evaluationid NUMBER PRIMARY KEY,
    Projectid NUMBER NOT NULL,
    Supervisorid NUMBER NOT NULL,
    Grade VARCHAR2(2) CHECK (Grade IN ('A', 'B', 'C', 'D', 'F')),
    Comments CLOB,
    Evaluationdate DATE DEFAULT SYSDATE,
    FOREIGN KEY (Projectid) REFERENCES Projects (Projectid),
    FOREIGN KEY (Supervisorid) REFERENCES Supervisors (Supervisorid)
);
