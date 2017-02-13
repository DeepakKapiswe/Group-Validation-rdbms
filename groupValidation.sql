/*
_rawMsg - msgTxt

rawMsg - msgId,msgTxt,timestamp,validationResult
groups - groupId,groupName,groupInfo,timestamp
groupMembers - groupId,rollNo,msgId
maybeGroups - groupId,timestamp,senderRollNo,senderEmailId,status
maybeGroupMembers - groupId,senderRollNo,memberRollNo,status
responses - responseText,status,numTry

auxTable - rollList
*/

PRAGMA foreign_keys=1;

DROP TABLE IF EXISTS [_rawMsg];
DROP TABLE IF EXISTS [_msgId];
DROP TABLE IF EXISTS [rawMsg];
DROP TABLE IF EXISTS [groups];
DROP TABLE IF EXISTS [groupMembers];
DROP TABLE IF EXISTS [maybeGroups];
DROP TABLE IF EXISTS [maybeGroupMembers];
DROP TABLE IF EXISTS [responses];

CREATE TABLE [_rawMsg]
(
    [msgTxt] TEXT  NOT NULL,
    CONSTRAINT [PKC__rawMsg] PRIMARY KEY  ([msgTxt])
);


CREATE TABLE [_msgId]
(
    [msgId] INTEGER  PRIMARY KEY AUTOINCREMENT
);


CREATE TABLE [rawMsg]
(
    [msgId] INTEGER NOT NULL,
    [msgTxt] TEXT  NOT NULL,
    [timestamp] TEXT NOT NULL,
    [validationResult] TEXT DEFAULT 'invalid',

    CONSTRAINT [PKC_rawMsg] PRIMARY KEY  ([msgId],[timestamp]),
    CONSTRAINT [CHK_rawMsg] CHECK ([validationResult] in ('valid', 'invalid')),
    FOREIGN KEY ([msgTxt]) REFERENCES [_rawMsg] ([msgTxt])
    ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY ([msgId]) REFERENCES [_msgId] ([msgId])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [groups]
(
  [groupId] INTEGER NOT NULL,
  [groupName] NVARCHAR(100) NOT NULL,
  [groupInfo] TEXT NOT NULL,
  [timestamp] TEXT NOT NULL,

  CONSTRAINT [PKC_rawMsg] PRIMARY KEY ([groupId]),
  FOREIGN KEY ([groupId]) REFERENCES [mayBeGroups] ([groupId]) 
  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [groupMembers]
(
    [groupId] INTEGER  NOT NULL,
    [rollNo] INTEGER  NOT NULL,
    [msgId] INTEGER  NOT NULL,

    CONSTRAINT [PKC_groupMembers] PRIMARY KEY ([groupId],[rollNo]),

    FOREIGN KEY ([groupId]) REFERENCES [maybeGroups] ([groupId])
    ON DELETE RESTRICT ON UPDATE CASCADE

  --  FOREIGN KEY ([msgId]) REFERENCES [rawMsg] ([msgId])
  --  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [maybeGroups]
(
    [groupId] INTEGER AUTO INCREMENT,
    [timestamp] TEXT  NOT NULL,
    [senderRollNo] INTEGER NOT NULL,
    [senderEmailId] TEXT NOT NULL,
    [status] TEXT NOT NULL,

    CONSTRAINT [PKC_maybeGroups] PRIMARY KEY  ([groupid],[senderRollNO]),

    CONSTRAINT [CHK_status] CHECK ([status] in ('validGroup', 'notValidGrpoup'))
);

CREATE TABLE [maybeGroupMembers]
(
    [groupId] INTEGER NOT NULL,
    [senderRollNO] INTEGER  NOT NULL,
    [memberRollNo] TEXT NOT NULL,
    [status] TEXT NOT NULL,

    CONSTRAINT [PKC_mayBeGroupMembers] PRIMARY KEY ([groupId],[senderRollNO]),
    FOREIGN KEY ([status]) REFERENCES [mayBeGroups] ([status]) 
    ON DELETE RESTRICT ON UPDATE CASCADE,

    FOREIGN KEY ([groupId]) REFERENCES [mayBeGroups] ([groupId]) 
    ON DELETE RESTRICT ON UPDATE CASCADE,

    FOREIGN KEY ([senderRollNO]) REFERENCES [mayBeGroups] ([senderRollNO]) 
    ON DELETE RESTRICT ON UPDATE CASCADE
);


/*
now create some triggers for fun

we will add a trigger that will record the attempts to insert or update records in courses table 
user input values will be stored in a table called log_courses along with the time of operation

select * from log_courses;

*/
/*
CREATE TABLE [log_courses]
(
    [eventtime] TEXT  NOT NULL,
    [courseid] NVARCHAR(10)  NOT NULL,
    [coursename] NVARCHAR(100)  NOT NULL,
    [courseinfo] NVARCHAR(1000)
);

*/
/*
CREATE TRIGGER trigger_insert_msgid BEFORE INSERT ON rawMsg FOR EACH ROW
BEGIN
  DECLARE mID INTEGER;
  SET mID = (SELECT AUTO_INCREMENT FROM groups.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rawMsg';
  SET NEW.msgId=mID;
END;
*/
/*
CREATE TRIGGER trigger_insert_raw_msg AFTER INSERT ON _rawMsg
BEGIN
  DECLARE mID INTEGER;
  insert into [_msgId] values (null);
  --SET mID = (SELECT AUTO_INCREMENT FROM groups.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='_msgId';
  insert into [rawMsg] ([msgId],[msgTxt],[timestamp]) values (mID,NEW.msgTxt,datetime('now'));
END;
*/
/*
CREATE TRIGGER trigger_log_courses BEFORE INSERT ON courses 
BEGIN
  insert into [log_courses] ([eventtime], [courseid], [coursename], [courseinfo]) values (datetime('now'), NEW.courseid, NEW.coursename, NEW.courseinfo);
END;
*/
