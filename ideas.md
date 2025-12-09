# Ideas for SQL Packages

## Contents

- [Ideas for SQL Packages](#ideas-for-sql-packages)
  - [Contents](#contents)
  - [Structure](#structure)
  - [Package Ideas](#package-ideas)
    - [Core Items](#core-items)
      - [Package 1 - Supervisor Package](#package-1---supervisor-package)
      - [Package 2 - Student Package](#package-2---student-package)
      - [Trigger - Email Notification Trigger](#trigger---email-notification-trigger)
    - [Additional Items](#additional-items)
      - [View - Extended Project Information View](#view---extended-project-information-view)
      - [Indexes](#indexes)

## Structure

To get good marks, 2 packages and 1 trigger are needed.

Across the 3 items, the following Oracle features should be used:

*The following features are checked if I think they are included in the code.*

- [x] Variables
- [x] %Type
- [x] %RowType
- [x] Operators
- Conditional Statements
  - [x] IF..ELSE
  - [x] CASE
- Loops
  - [x] Basic LOOP
  - [x] FOR LOOP
  - [x] WHILE LOOP
  - [ ] Nested Loops
- [x] String operations (maybe)
- [x] Arrays
- [x] Procedures
- [x] Functions
- Cursors
  - [x] Implicit Cursors
  - [x] Explicit Cursors
- Records
  - [x] Table Records
  - [x] Cursor Records
  - [x] User-Defined Records
- Exception Handling
  - [x] System-defined Exceptions
  - [x] User-defined Exceptions
- [x] Triggers
- [x] Packages
- Collections (maybe)
  - [x] Index-by Tables
  - [x] Nested Tables
  - [x] Varrays
- [x] Transactions
  - *Be good to demonstrate COMMIT, ROLLBACK, SAVEPOINT*
- [x] Printing output using DBMS_OUTPUT.PUT_LINE
- [x] Object oriented PL/SQL features
- [x] Dynamic SQL (if possible)

Additionally, I can create Views and Indexes as smaller separate components / items to show further understanding. For example:

- A view to extend project information with marking, student and supervisor details.
- An index on the project table to speed up lookups by student (This index here should depend on whatever functionality I implement in the packages / trigger).

## Package Ideas

### Core Items

#### Package 1 - Supervisor Package

- Procedure to mark projects (Using Parameters, Transactions)
- Function to get grade based on passed mark (CASE)
- Function to calculate pass/fail (IF..ELSE)
- Procedure to get student's average mark across all projects (Implicit Cursor, LOOP)
  - This will be replaced by a produce student report procedure.
  - This will make use of dynamic SQL to build a table name based on student ID.
  - It will output the average mark.
  - It will also include a summary of the student's performance (e.g. number of projects passed/failed).
- Get list of projects supervised by a supervisor for a status (Explicit Cursor, Cursor Records, FOR LOOP)
- Exception handling for invalid project IDs, invalid marks, etc.
- Procedure to remark a project (Using Parameters, Explicit Cursor)
- Procedure to view projects ready for marking
- Procedure to get notifications for a supervisor
  - Procedure to acknowledge receipt of evaluation requests (Set that notification as read)
  - This could use OOP here to make a notification object with methods to mark as read, get details, etc.

#### Package 2 - Student Package

- Procedure to get projects by status for a student
- Procedure to get project and performance summary (i.e. Average mark, grade, number of projects passed/failed, number of projects pending)
- Function to calculate overall grade across all projects (Implicit Cursor, LOOP)
- Procedure to submit a project (Using Parameters, Transactions)
- Procedure to view feedback for a project
- Exception handling for invalid project IDs, unauthorized access, etc.
- Procedure to get current notifications for a student
  - Procedure to acknowledge receipt of feedback (Set that notification as read)
  - This could use OOP here to make a notification object with methods to mark as read, get details, etc.

#### Trigger - Email Notification Trigger

When an evaluation record is inserted or updated, append a notification message to a log table indicating that an email would be sent to the student.

This should include what grade they got and any comments from the supervisor.

Additionally, I could think about having different types of notifications. For example, student and staff notifications.

- For student notifications, it could have a pass email, fail email.
- Maybe a separate trigger for if a project is remarked? (<-- This can be done in a single trigger with conditional logic to figure out which type of operation is performed).
- For staff notifications, it could be a proof of evaluation/receipt email.

^ I can embed some string logic here too.

For example, I could embed the type of evaluation into its ID.

ps001 = Passed
fs001 = Failed
rs001 = Remarked
rc001 = Receipt for staff

I could also have a type column in this table to show if an email is for staff or student.

I could use a collection here to define different email templates for each type of notification.

For example

| Type | Subject            | Body                                   | Audience |
|------|--------------------|----------------------------------------|----------|
| ps   | Project Passed     | Congratulations, you have passed...    | Student  |
| fs   | Project Failed     | Unfortunately, you have not passed...  | Student  |
| rs   | Project Remarked   | Your project has been remarked...      | Student  |
| rc   | Evaluation Receipt | An evaluation has been recorded...     | Staff    |

### Additional Items

#### View - Extended Project Information View

Create a view to extend project information with marking, student and supervisor details.

#### Indexes

- Index on project table to speed up lookups by student ID and status.
- Index on project table to speed up lookups by supervisor ID and status.
- Index on notification table to speed up lookups by person ID (StudentID if student, SupervisorID if supervisor) and notification status (read/unread).
