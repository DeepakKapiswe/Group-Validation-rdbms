/*
rawMsg - msgId,msgTxt,timestamp,validationResult
maybeGroups - groupId,timestamp,senderRollNo,senderEmailId,status
maybeGroupMembers - groupId,senderRollNo,memberRollNo,status
maybeAgreedGroups - groupId,memberRollNo
finalGroups - groupId,memberRollNo
*/

PRAGMA foreign_keys=1;
PRAGMA recursive_triggers = ON;

begin transaction;
DROP TABLE IF EXISTS [_rawMsg];
DROP TABLE IF EXISTS [rawMsg];
DROP TABLE IF EXISTS [rawMembers];
DROP TABLE IF EXISTS [currentMembersGId];
DROP TABLE IF EXISTS [currentMembers];
DROP TABLE IF EXISTS [nonAgreedGroups];
DROP TABLE IF EXISTS [maybeGroupMembers];
DROP TABLE IF EXISTS [maybeGroups];
DROP TABLE IF EXISTS [conflictingGroupMember];
DROP TABLE IF EXISTS [lengthExceededGroups];
DROP TABLE IF EXISTS [finalGroups];
DROP TABLE IF EXISTS [maybeAgreedGroups];
DROP TABLE IF EXISTS [tempMembers];
DROP TABLE IF EXISTS [aux_semanticChecker];
DROP TABLE IF EXISTS [groupLengthLimit];
DROP TABLE IF EXISTS [generateGroupReport];
DROP TABLE IF EXISTS [responses];
DROP TABLE IF EXISTS [generateResponse];
DROP TABLE IF EXISTS [senderEmails];

CREATE TABLE [_rawMsg]
(
    [msg] TEXT NOT NULL,
    [senderEmail] TEXT NOT NULL,
    CONSTRAINT [PKC__rawmsg] PRIMARY KEY ([msg],[senderEmail])
);

CREATE TABLE [senderEmails]
(
    [senderEmailId] TEXT PRIMARY KEY
);

CREATE TABLE [rawMembers]
(
    [msg] TEXT PRIMARY KEY
);

CREATE TABLE [rawMsg]
(
    [msgId] INTEGER PRIMARY KEY AUTOINCREMENT,
    [msgTxt] INTEGER  NOT NULL,
    [senderEmailId] TEXT  NOT NULL,
    [timestamp] TEXT NOT NULL,
    [validationResult] TEXT DEFAULT 'invalid',

    CONSTRAINT [CHK_rawMsg] CHECK ([validationResult] in ('valid', 'invalid'))
    FOREIGN KEY ([senderEmailId]) REFERENCES [senderEmails] ([senderEmailId])
    ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE [maybeGroups]
(
    [groupId] INTEGER,
    [timestamp] TEXT  NOT NULL,
    [senderRollNo] INTEGER NOT NULL,
    [senderEmailId] TEXT NOT NULL,

    CONSTRAINT [PKC_maybeGroups] PRIMARY KEY  ([groupId],[senderRollNo])
    FOREIGN KEY ([senderEmailId]) REFERENCES [senderEmails] ([senderEmailId])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [maybeGroupMembers]
(
    [groupId] INTEGER NOT NULL,
    [senderRollNo] INTEGER  NOT NULL,
    [memberRollNo] INTEGER NOT NULL,
    [agreementStatus] TEXT NOT NULL default 'No',

    CONSTRAINT [PKC_mayBeGroupMembers] PRIMARY KEY ([groupId],[senderRollNo],[memberRollNo]),

    CONSTRAINT [CHK_agreementStatus] CHECK ([agreementStatus] in ('Yes','No')),

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

CREATE TABLE [aux_semanticChecker]
(
    [val] INTEGER NOT NULL,
    CONSTRAINT [PKC_aux_semanticChecker] PRIMARY KEY ([val])
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
    [senderEmailId] TEXT PRIMARY KEY,
    [msg] TEXT NOT NULL
);

CREATE TABLE [generateResponse]
(
    [val] INTEGER PRIMARY KEY
);

CREATE TRIGGER insertEmailId after insert on _rawMsg
begin
    insert into senderEmails values(new.senderEmail);
end;

CREATE TRIGGER splitMsgWithMembers after insert on _rawMsg
when (select instr(new.msg,'\n')) > 0
  begin
    delete from rawMembers;
    delete from tempMembers;
    insert into rawMembers select substr(new.msg,(select instr(new.msg,'\n')+2));
    insert into rawMsg(msgTxt,senderEmailId,timestamp,validationResult) values ((select substr(new.msg,1,(select instr(new.msg,'\n')-1))),new.senderEmail,datetime('now'),'valid');
  end;

CREATE TRIGGER splitMsgWithoutMembers after insert on _rawMsg
when (select instr(new.msg,'\n'))=0
  begin
    delete from rawMembers;
    delete from tempMembers;
    insert into rawMsg (msgTxt,senderEmailId,timestamp,validationResult) values (cast(new.msg as INTEGER),new.senderEmail,datetime(),'valid');
  end;

CREATE TRIGGER splitMembers after insert on rawMembers
when (select length(new.msg)) > 0
  begin
    insert into tempMembers select cast((select substr(new.msg,1,(select instr(new.msg,'\n')-1))) as INTEGER);
    insert into rawMembers select substr(new.msg,(select instr(new.msg,'\n')+2));
  end;


CREATE TRIGGER insertInmaybeGroups after insert on rawMsg
when new.validationResult='valid'
  begin
    /*delete from rawMembers;*/
    insert into maybeGroups values(new.msgId,new.timestamp,(select cast(new.msgTxt as INTEGER)),new.senderEmailId);
  end;


CREATE TRIGGER insertMembers after insert on maybeGroups
begin
    insert into maybeGroupMembers (groupId,senderRollNo,memberRollNo) select * from (select groupId,senderRollNo from maybeGroups where groupId =new.groupId) inner join tempMembers;

    delete from currentMembers;
    delete from currentMembersGId;
    delete from aux_semanticChecker;
    insert into currentMembers select groupId,senderRollNo,memberRollNo from maybeGroupMembers where groupId = new.groupId;
    insert into currentMembersGId select groupId,senderRollNo from maybeGroups where groupId=new.groupId;

    insert into aux_semanticChecker values (1);
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

create trigger checkIfAgreedGroup after insert on aux_semanticChecker
when (select count(agreementStatus) from maybeGroupMembers where groupId in (select groupId from currentMembersGId) and agreementStatus='No') = 0
begin
    insert into maybeAgreedGroups  select * from ((select group_concat(groupId,'') from currentMembersGId) inner join currentMembersGId);
    delete from tempMembers;
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



insert into _rawMsg values('13\n49\n19\n','yhty@gmail.com');
insert into _rawMsg values('19\n49\n13\n','sknn@gmail.com');
insert into _rawMsg values('49\n13\n19\n','etgt@gmail.com');

insert into _rawMsg values('50\n','setgt@gmail.com');

insert into _rawMsg values('41\n50\n','ewwwtgt@gmail.com');


insert into _rawMsg values('1\n2\n3\n4\n','daetgt@gmail.com');
insert into _rawMsg values('2\n1\n3\n4\n','edatgt@gmail.com');
insert into _rawMsg values('3\n2\n1\n4\n','wdtgt@gmail.com');
insert into _rawMsg values('4\n2\n3\n1\n','detgt@gmail.com');


insert into _rawMsg values('5\n6\n7\n','qetgt@gmail.com');
insert into _rawMsg values('7\n6\n5\n','wetgt@gmail.com');
insert into _rawMsg values('6\n5\n7\n','eetgt@gmail.com');

insert into _rawMsg values('15\n16\n7\n','retgt@gmail.com');
insert into _rawMsg values('7\n16\n15\n','tetgt@gmail.com');
insert into _rawMsg values('16\n15\n7\n','yetgt@gmail.com');


insert into groupLengthLimit(length) values(3);


insert into generateGroupReport values(1);
insert into generateresponse values (1);

end;

select * from nonAgreedGroups;
select * from conflictinggroupmember where memberrollno in (select memberRollNo from conflictinggroupmember group by memberRollNo having count()>1);
select * from lengthExceededGroups;
select * from finalGroups;
select * from responses;

