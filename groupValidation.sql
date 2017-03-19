/*
rawMsg - msgId,msgTxt,timestamp,validationResult
maybeGroups - groupId,timestamp,senderRollNo,senderEmailId,status
maybeGroupMembers - groupId,senderRollNo,memberRollNo,status
maybeAgreedGroups - groupId,memberRollNo
finalGroups - groupId,memberRollNo
*/

PRAGMA foreign_keys=1;

begin transaction;
DROP TABLE IF EXISTS [rawMsg];
DROP TABLE IF EXISTS [currentMembersGId];
DROP TABLE IF EXISTS [currentMembers];
DROP TABLE IF EXISTS [currentGId];
DROP TABLE IF EXISTS [nonAgreedGroups];
DROP TABLE IF EXISTS [maybeGroupMembers];
DROP TABLE IF EXISTS [maybeGroups];
DROP TABLE IF EXISTS [conflictingGroupMember];
DROP TABLE IF EXISTS [lengthExceededGroups];
DROP TABLE IF EXISTS [finalGroups];
DROP TABLE IF EXISTS [maybeAgreedGroups];
DROP TABLE IF EXISTS [tempMembers];
DROP TABLE IF EXISTS [aux_sematicChecker];
DROP TABLE IF EXISTS [groupLengthLimit];
DROP TABLE IF EXISTS [generateGroupReport];
DROP TABLE IF EXISTS [responses];
DROP TABLE IF EXISTS [generateResponse];

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
    [memberRollNo] INTEGER NOT NULL,
    CONSTRAINT [PKC_maybeAgreedGroups] PRIMARY KEY ([finalGId],[groupId],[memberRollNo])
);

CREATE TABLE [finalGroups]
(
    [finalGId] TEXT NOT NULL,
    [groupId] INTEGER NOT NULL,
    [memberRollNo] INTEGER NOT NULL,

    CONSTRAINT [PKC_finalGroups] PRIMARY KEY ([finalGId],[groupId],[memberRollNo]),
    FOREIGN KEY ([finalGId],[groupId],[memberRollNo]) REFERENCES [maybeAgreedGroups] ([finalGId],[groupId],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [nonAgreedGroups]
(
    [groupId] INTEGER NOT NULL,
    [senderRollNo] INTEGER NOT NULL,

    CONSTRAINT [PKC_nonAgreedGroups] PRIMARY KEY ([groupId],[senderRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo]) REFERENCES [maybeGroups] ([groupId],[senderRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [conflictingGroupMember]
(
    [finalGId] TEXT NOT NULL,
    [groupId] INTEGER NOT NULL,
    [memberRollNo] INTEGER NOT NULL,

    CONSTRAINT [PKC_conflictingGroupMember] PRIMARY KEY ([finalGId],[groupId],[memberRollNo])
    FOREIGN KEY ([finalGId],[groupId],[memberRollNo]) REFERENCES [maybeAgreedGroups] ([finalGId],[groupId],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [lengthExceededGroups]
(
    [finalGId] TEXT NOT NULL,
    [groupId] INTEGER NOT NULL,
    [memberRollNo] INTEGER NOT NULL,

    CONSTRAINT [PKC_lengthExceededGroup] PRIMARY KEY ([finalGId],[groupId],[memberRollNo])
    FOREIGN KEY ([finalGId],[groupId],[memberRollNo]) REFERENCES [maybeAgreedGroups] ([finalGId],[groupId],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [tempMembers]
(
    [memberRollNo] INTEGER NOT NULL,
    CONSTRAINT [PKC_tempMembers] PRIMARY KEY ([memberRollNo])
);

CREATE TABLE [aux_sematicChecker]
(
    [val] INTEGER NOT NULL,
    CONSTRAINT [PKC_aux_sematicChecker] PRIMARY KEY ([val])
);

CREATE TABLE [generateGroupReport]
(
    [val] INTEGER NOT NULL,
    CONSTRAINT [PKC_generateGroupReport] PRIMARY KEY ([val])
);

CREATE TABLE [groupLengthLimit]
(
    [id] INTEGER AUTO INCREMENT,
    [length] INTEGER NOT NULL,
    CONSTRAINT [PKC_groupLengthLimit] PRIMARY KEY ([id])
);

CREATE TABLE [responses]
(
    [msg] TEXT NOT NULL,
    [senderEmailId] TEXT PRIMARY KEY
);

CREATE TABLE [generateResponse]
(
    [val] INTEGER NOT NULL,
    CONSTRAINT [PKC_generateResponse] PRIMARY KEY ([val])
);

CREATE TRIGGER insertMembers after insert on maybeGroups
begin
    insert into maybeGroupMembers (groupId,senderRollNo,memberRollNo) select * from (select groupId,senderRollNo from maybeGroups where groupId =new.groupId) inner join tempMembers;

    delete from currentMembers;
    delete from currentMembersGId;
    delete from aux_sematicChecker;
    insert into currentMembers select groupId,senderRollNo,memberRollNo from maybeGroupMembers where groupId = new.groupId;
    insert into currentMembersGId select groupId,senderRollNo from maybeGroups where groupId=new.groupId;

    insert into aux_sematicChecker values (1);
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

create trigger checkIsValidGroup after insert on aux_sematicChecker
when (select count(agreementStatus) from maybeGroupMembers where groupId in (select groupId from currentMembersGId) and agreementStatus='No') = 0
begin
    insert into maybeAgreedGroups  select * from ((select group_concat(groupId,'') from currentMembersGId) inner join currentMembersGId);
end;

CREATE TRIGGER generateReport after insert on generateGroupReport
begin
    delete from nonAgreedGroups;
    delete from conflictingGroupMember;
    delete from lengthExceededGroups;
    delete from finalGroups;

    insert into nonAgreedGroups select distinct groupId,senderRollNo from maybeGroupMembers where agreementStatus='No';

    insert into conflictingGroupMember select * from maybeAgreedGroups where finalGId in (select finalGId from maybeAgreedGroups where memberRollNo in (select memberRollNo from maybeAgreedGroups group by memberRollNo having count(*)>1));

    insert into lengthExceededGroups select * from maybeAgreedGroups where finalGId in (select finalGId from maybeAgreedGroups group by finalGId having count(memberRollNo) > (select length from groupLengthLimit order by id desc limit 1));

    insert into finalGroups select * from maybeAgreedGroups where finalGId not in (select finalGId from conflictingGroupMember) and finalGId not in (select finalGId from lengthExceededGroups);

    delete from generateGroupReport;
end;

CREATE TRIGGER generateResponses after insert on generateResponse
begin
  delete from responses;
  insert into responses select * from (select senderEmailId,'No application got in favour of -> '||sroll||' from '||mrolls from maybeGroups inner join (select senderRollNo as sroll,group_concat(memberRollNo) as mrolls from maybeGroupmembers where groupid in (select groupid from nonagreedgroups) and agreementstatus='No' group by groupid) where sroll=senderRollno);
end;




insert into groupLengthLimit(length) values(2);

insert into tempMembers values (13);
insert into tempMembers values (49);
insert into maybeGroups values (1,datetime('now'),19,'sknn@gmail.com');

insert into tempMembers values (19);
insert into tempMembers values (49);
insert into maybeGroups values (2,datetime('now'),13,'yhty@gmail.com');

insert into tempMembers values (19);
insert into tempMembers values (13);
insert into maybeGroups values (3,datetime('now'),49,'etgt@gmail.com');


insert into tempMembers values (15);
insert into tempMembers values (16);
insert into maybeGroups values(4,datetime('now'),114,'rgrgr@gmail.com');

insert into tempMembers values (1232);
insert into tempMembers values (1623);
insert into maybeGroups values(12,datetime('now'),234,'sdaswrgr@gmail.com');

insert into maybeGroups values(5,datetime('now'),115,'23we3@gmail.com');

insert into generateGroupReport values(1);
insert into generateresponse values (1);
end;
select * from nonAgreedGroups;
select * from conflictingGroupMember;
select * from lengthExceededGroups;
select * from finalGroups;
select * from responses;
--select senderRollNO,group_concat(memberRollNo) from maybeGroupMembers where groupId in (select groupId from nonAgreedGroups) and agreementStatus='No' group by groupId;

--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(1,111,112);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(1,111,113);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(2,112,111);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(2,112,113);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(3,113,111);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(3,113,112);
--insert into maybeGroupMembers(groupId,senderRollNo,memberRollNo) values(4,114,115);
