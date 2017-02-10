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

CREATE TABLE [groupMembers]
(
    [groupId] INTEGER  NOT NULL,
    [rollNo] INTEGER  NOT NULL,
    [msgId] INTEGER  NOT NULL,

    CONSTRAINT [PKC_groupMembers] PRIMARY KEY ([groupId],[rollNo])

    FOREIGN KEY ([groupId]) REFERENCES [maybeGroups] ([groupId]) 
		ON DELETE RESTRICT ON UPDATE CASCADE,

    FOREIGN KEY ([msgId]) REFERENCES [rawMsg] ([msgId]) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
    
);

CREATE TABLE [groups]
(
  [groupId] INTEGER NOT NULL,
  [groupName] NVARCHAR(100) NOT NULL,
  [groupInfo] TEXT NOT NULL,
  [timestamp] TEXT NOT NULL,

  CONSTRAINT [PKC_rawMsg] PRIMARY KEY ([groupId]),
  
  FOREIGN KEY ([groupId]) REFERENCES [mayBeGroups] ([groupId]) 
		ON DELETE RESTRICT ON UPDATE CASCADE,

CREATE TABLE [mayBeGroups]
(
    [groupId] INTEGER  NOT NULL AUTO INCREMENT,
    [timestamp] TEXT  NOT NULL,
    [senderRollNo] INTEGER NOT NULL,
    [senderEmailId] TEXT NOT NULL,
    [status] TEXT NOT NULL,
    
    CONSTRAINT [PKC_mayBeGroups] PRIMARY KEY  ([groupid],[senderRollNO])
		ON DELETE RESTRICT ON UPDATE CASCADE,
    
    CONSTRAINT [CHK_status] CHECK ([status] in ('validGroup', 'notValidGrpoup'))
		ON DELETE RESTRICT ON UPDATE CASCADE,
);

CREATE TABLE [mayBeGroupMembers]
(
    [groupId] INTEGER NOT NULL
    [senderRollNO] INTEGER  NOT NULL,
    [groupId] INTEGER  NOT NULL,
    [memberRollNo] TEXT NOT NULL,
    [status] TEXT NOT NULL,
    
    CONSTRAINT [PKC_mayBeGroupMembers] PRIMARY KEY ([groupId],[senderRollNO])

    FOREIGN KEY ([status]) REFERENCES [mayBeGroups] ([status]) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
    
    FOREIGN KEY ([groupId]) REFERENCES [mayBeGroups] ([groupId]) 
		ON DELETE RESTRICT ON UPDATE CASCADE
    
    FOREIGN KEY ([senderRollNO]) REFERENCES [mayBeGroups] ([senderRollNO]) 
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

