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

- Variables
- %Type
- Operators
- Conditional Statements
  - IF..ELSE
  - CASE
- Loops
  - Basic LOOP
  - FOR LOOP
  - WHILE LOOP
  - Nested Loops
- String operations (maybe)
- Arrays
- Procedures
- Functions
- Cursors
  - Implicit Cursors
  - Explicit Cursors
- Records
  - Table Records
  - Cursor Records
  - User-Defined Records
- Exception Handling
  - System-defined Exceptions
  - User-defined Exceptions
- Triggers
- Packages
- Collections (maybe)
- Transactions
  - Be good to demonstrate COMMIT, ROLLBACK, SAVEPOINT
- Printing output using DBMS_OUTPUT.PUT_LINE
- Object oriented PL/SQL features
- Dynamic SQL (if possible)

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
- Get list of projects supervised by a supervisor (Explicit Cursor, Cursor Records, FOR LOOP)
- Exception handling for invalid project IDs, invalid marks, etc.
- Procedure to remark a project (Using Parameters, Transactions, SAVEPOINT)
- Procedure to view projects ready for marking
- Procedure to get notifications for a supervisor
  - Procedure to acknowledge receipt of evaluation requests (Set that notification as read)
  - This could use OOP here to make a notification object with methods to mark as read, get details, etc.

#### Package 2 - Student Package

- Procedure to get projects by status
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

| Type | Subject | Body | Audience |
|------|---------|------|----------|
| ps   | Project Passed | Congratulations, you have passed... | Student |
| fs   | Project Failed | Unfortunately, you have not passed... | Student |
| rs   | Project Remarked | Your project has been remarked... | Student |
| rc   | Evaluation Receipt | An evaluation has been recorded... | Staff |

### Additional Items

#### View - Extended Project Information View

Create a view to extend project information with marking, student and supervisor details.

#### Indexes

- Index on project table to speed up lookups by student ID.
- Index on evaluation table to speed up lookups by supervisor ID.
- Index on notification table to speed up lookups by student ID and notification status (read/unread).
- Index on notification table to speed up lookups by staff ID and notification status (read/unread).
- Index on project status to speed up lookups by project status (pending, completed, etc.).
