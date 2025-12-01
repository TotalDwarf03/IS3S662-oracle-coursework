CREATE TABLE Supervisors (
    Supervisorid NUMBER PRIMARY KEY,
    Fullname VARCHAR2(100) NOT NULL,
    Email VARCHAR2(100) UNIQUE NOT NULL,
    Department VARCHAR2(100)
);
