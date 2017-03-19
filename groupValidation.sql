/*
rawMsg - msgId,msgTxt,timestamp,validationResult
maybeGroups - groupId,timestamp,senderRollNo,senderEmailId,status
maybeGroupMembers - groupId,senderRollNo,memberRollNo,status
maybeAgreedGroups - groupId,memberRollNo
finalGroups - groupId,memberRollNo
*/

PRAGMA foreign_keys=1;

DROP TABLE IF EXISTS [rawMsg];
DROP TABLE IF EXISTS [currentMembersGId];
DROP TABLE IF EXISTS [currentMembers];
DROP TABLE IF EXISTS [currentGId];
DROP TABLE IF EXISTS [maybeGroupMembers];
DROP TABLE IF EXISTS [maybeGroups];
DROP TABLE IF EXISTS [maybeAgreedGroups];
DROP TABLE IF EXISTS [finalGroups];
DROP TABLE IF EXISTS [tempMembers];
DROP TABLE IF EXISTS [aux];

CREATE TABLE [rawMsg]
(
    [msgId] INTEGER NOT NULL,
    [msgTxt] TEXT  NOT NULL,
    [timestamp] TEXT NOT NULL,
    [validationResult] TEXT DEFAULT 'invalid',

    CONSTRAINT [PKC_rawMsg] PRIMARY KEY  ([msgId]),
    CONSTRAINT [CHK_rawMsg] CHECK ([validationResult] in ('valid', 'invalid'))
);

CREATE TABLE [maybeGroups]
(
    [groupId] INTEGER,
    [timestamp] TEXT  NOT NULL,
    [senderRollNo] INTEGER NOT NULL,
    [senderEmailId] TEXT NOT NULL,

    CONSTRAINT [PKC_maybeGroups] PRIMARY KEY  ([groupId],[senderRollNo])
);

CREATE TABLE [maybeGroupMembers]
(
    [groupId] INTEGER NOT NULL,
    [senderRollNo] INTEGER  NOT NULL,
    [memberRollNo] INTEGER NOT NULL,
    [agreementStatus] TEXT NOT NULL default 'No',

    CONSTRAINT [CHK_agreementStatus] CHECK ([agreementStatus] in ('Yes','No')),
    CONSTRAINT [PKC_mayBeGroupMembers] PRIMARY KEY ([groupId],[senderRollNo],[memberRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo]) REFERENCES [maybeGroups] ([groupId],[senderRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [currentGId]
(
    [groupId] INTEGER NOT NULL,
    [senderRollNo] INTEGER  NOT NULL,

    CONSTRAINT [PKC_groupId] PRIMARY KEY ([groupId],[senderRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo]) REFERENCES [maybeGroups] ([groupId],[senderRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [currentMembers]
(
    [groupId] INTEGER NOT NULL,
    [senderRollNo] INTEGER  NOT NULL,
    [memberRollNo] INTEGER NOT NULL,

    CONSTRAINT [PKC_currentGroupMembers] PRIMARY KEY ([groupId],[senderRollNo],[memberRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo],[memberRollNo]) REFERENCES [maybeGroupMembers] ([groupId],[senderRollNo],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [currentMembersGId]
(
    [groupId] INTEGER NOT NULL,
    [senderRollNo] INTEGER  NOT NULL,

    CONSTRAINT [PKC_groupId] PRIMARY KEY ([groupId],[senderRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo]) REFERENCES [maybeGroups] ([groupId],[senderRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [maybeAgreedGroups]
(
    [finalGId] TEXT NOT NULL,
    [groupId] INTEGER NOT NULL,
    [memberRollNo] INTEGER,
    CONSTRAINT [PKC_maybeAgreedGroups] PRIMARY KEY ([finalGId],[groupId],[memberRollNo])
);

CREATE TABLE [finalGroups]
(
    [finalGId] INTEGER NOT NULL,
    [memberRollNo] INTEGER NOT NULL,
    [groupId] INTEGER NOT NULL,

    CONSTRAINT [PKC_finalGroups] PRIMARY KEY ([finalGId],[groupId],[memberRollNo]),
    FOREIGN KEY ([finalGId],[groupId],[memberRollNo]) REFERENCES [maybeAgreedGroups] ([finalGId],[groupId],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [tempMembers]
(
    [memberRollNo] INTEGER NOT NULL,
    CONSTRAINT [PKC_tempMembers] PRIMARY KEY ([memberRollNo])
);

CREATE TABLE [aux]
(
    [val] INTEGER NOT NULL,
    CONSTRAINT [PKC_aux] PRIMARY KEY ([val])
);


CREATE TRIGGER insertMembers after insert on maybeGroups
begin
    insert into maybeGroupMembers (groupId,senderRollNo,memberRollNo) select * from (select groupId,senderRollNo from maybeGroups where groupId =new.groupId) inner join tempMembers;

    delete from currentMembers;
    delete from aux;
    insert into currentMembers select groupId,senderRollNo,memberRollNo from maybeGroupMembers where groupId = new.groupId;
    insert into currentMembersGId select groupId,senderRollNo from maybeGroups where groupId=new.groupId;

    insert into aux values (1);
end;

CREATE TRIGGER insertCurrentMemberGId after insert on currentMembers
begin
    insert into currentMembersGId select groupId,senderRollNo from maybeGroupMembers where senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo;
    delete from tempMembers;
end;

CREATE TRIGGER updateAgreeStatus after insert on maybeGroupMembers
when (select count(*) from maybeGroupMembers where agreementStatus='No' and senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo) = 1
begin
    update maybeGroupMembers set agreementStatus='Yes' where groupId=new.groupId and senderRollNo=new.senderRollNo and memberRollNo=new.memberRollNo;
    update maybeGroupMembers set agreementStatus='Yes' where  senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo;
end;

create trigger checkIsValidGroup after insert on aux
when (select count(agreementStatus) from maybeGroupMembers where groupId in (select groupId from currentMembersGId) and agreementStatus='No') = 0
begin
  insert into maybeAgreedGroups  select * from (select * from ((select group_concat(groupId,'') from currentMembersGId) inner join currentMembersGId));
end;

insert into tempMembers values (13);
insert into tempMembers values (49);

insert into maybeGroups values (1,datetime('now'),19,'sknn@gmail.com');
delete from currentMembersGId;
insert into tempMembers values (19);
insert into tempMembers values (49);
insert into maybeGroups values (2,datetime('now'),13,'yhty@gmail.com');
delete from currentMembersGId;
insert into tempMembers values (19);
insert into tempMembers values (13);
insert into maybeGroups values (3,datetime('now'),49,'etgt@gmail.com');



--insert into maybeGroups values(4,datetime('now'),114,'rgrgr@gmail.com');
--insert into maybeGroups values(5,datetime('now'),115,'rgrgr@gmail.com');


--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(1,111,112);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(1,111,113);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(2,112,111);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(2,112,113);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(3,113,111);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(3,113,112);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(4,114,115);


--select groupId from maybeGroupMembers where senderRollNo= (select memberRollNo from (select * from (select memberRollNo,senderRollNo from maybeGroupMembers where groupId = (select groupId from maybeGroups order by groupId limit 1)) limit 1)) and memberRollNo = (select senderRollNo from (select * from (select memberRollNo,senderRollNo from maybeGroupMembers where groupId = (select groupId from maybeGroups order by groupId limit 1)) limit 1));


--select * from (select memberRollNo,senderRollNo from maybeGroupMembers where groupId = (select groupId from maybeGroups order by groupId limit 1))

