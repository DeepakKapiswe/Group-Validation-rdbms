/* 
rawMsg - msgId,msgTxt,timestamp,validationResult
groups - groupId,groupName,groupInfo,timestamp
groupMembers - groupId,rollNo,msgId
maybeGroups - groupId,timestamp,senderRollNo,senderEmailId,status
maybeGroupMembers - groupId,senderRollNo,memberRollNo,status
responses - responseText,status,numTry
*/

PRAGMA foreign_keys=1;

DROP TABLE IF EXISTS [rawMsg];
DROP TABLE IF EXISTS [groups];
DROP TABLE IF EXISTS [groupMembers];
DROP TABLE IF EXISTS [maybeGroups];
DROP TABLE IF EXISTS [maybeGroupMembers];
DROP TABLE IF EXISTS [responses];

CREATE TABLE [rawMsg]
(
    [msgId] INTEGER NOT NULL AUTO INCREMENT,
    [msgTxt] TEXT  NOT NULL,
    [timestamp] TEXT  NOT NULL,
    [validationResult]  NOT NULL,

    CONSTRAINT [PKC_rawMsg] PRIMARY KEY  ([msgId])
    CONSTRAINT [CHK_rawMsg] CHECK ([validationResult] in ('valid', 'invalid'))
);

CREATE TABLE [students]
(
    [rollno] NVARCHAR(5)  NOT NULL,
    [studentfname] NVARCHAR(100)  NOT NULL,
    [studentmname] NVARCHAR(100),
    [studentlname] NVARCHAR(100)  NOT NULL,
    [studentTitle] NVARCHAR(5)  NOT NULL,
    [studentDegree] NVARCHAR(5)  NOT NULL, /* mca/msc/mtech */
    [studentEmail] NVARCHAR(200)  NOT NULL,
    [studentMobile] NVARCHAR(20)  NOT NULL,
    /* now add constraints */
    CONSTRAINT [PKC_students] PRIMARY KEY  ([rollno])
);

CREATE TABLE [courses]
(
    [courseid] NVARCHAR(10)  NOT NULL,
    [coursename] NVARCHAR(100)  NOT NULL,
    [courseinfo] NVARCHAR(1000),
    /* now add constraints */
    CONSTRAINT [PKC_courses] PRIMARY KEY  ([courseid])
    /* additional check constraints */
    CONSTRAINT [CHK_courseid] CHECK ([courseid] in ('ip', 'mf', 'cmgt', 'dbms', 'co'))
);

CREATE TABLE [teachercourses]
(
    [teacherid] NVARCHAR(5)  NOT NULL,
    [courseid] NVARCHAR(10)  NOT NULL,
    /* now add constraints */
    CONSTRAINT [PKC_teachercourses] PRIMARY KEY  ([teacherid], [courseid]),
    FOREIGN KEY ([teacherid]) REFERENCES [teachers] ([teacherid]) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY ([courseid]) REFERENCES [courses] ([courseid]) 
		ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [studentcourses]
(
    [rollno] NVARCHAR(5)  NOT NULL,
    [courseid] NVARCHAR(10)  NOT NULL,
    /* now add constraints */
    CONSTRAINT [PKC_studentcourses] PRIMARY KEY  ([rollno], [courseid]),
    FOREIGN KEY ([rollno]) REFERENCES [students] ([rollno]) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY ([courseid]) REFERENCES [courses] ([courseid]) 
		ON DELETE RESTRICT ON UPDATE CASCADE
);

/*
now create some triggers for fun

we will add a trigger that will record the attempts to insert or update records in courses table 
user input values will be stored in a table called log_courses along with the time of operation

select * from log_courses;

*/

CREATE TABLE [log_courses]
(
    [eventtime] TEXT  NOT NULL,
    [courseid] NVARCHAR(10)  NOT NULL,
    [coursename] NVARCHAR(100)  NOT NULL,
    [courseinfo] NVARCHAR(1000)
    /* 
       no additional constraints are needed per se as this table will be 
       used only interally by the trigger 
     */
);

CREATE TRIGGER trigger_log_courses BEFORE INSERT ON courses 
BEGIN
  insert into [log_courses] ([eventtime], [courseid], [coursename], [courseinfo]) values (datetime('now'), NEW.courseid, NEW.coursename, NEW.courseinfo);
END;

