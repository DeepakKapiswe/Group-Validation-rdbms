
/*

foreign/primary key errors to be handled [after changing to mysql]

reminders be generated on trigger

*/
PRAGMA foreign_keys=1;
PRAGMA recursive_triggers = ON;

begin transaction;

DROP TABLE IF EXISTS [aux_userApplicationInfo];
DROP TABLE IF EXISTS [aux_maybeRollNos];
DROP TABLE IF EXISTS [aux_currentGroupMembersGIds];
DROP TABLE IF EXISTS [aux_currentGroupMembersRollNos];
DROP TABLE IF EXISTS [aux_maybeGroupMembers];
DROP TABLE IF EXISTS [aux_maybeGroups];
DROP TABLE IF EXISTS [aux_agreedGroups];
DROP TABLE IF EXISTS [aux_maybeMemberRollNos];
DROP TABLE IF EXISTS [aux_flag2trigger_checkIfGroupMembersAgree];
DROP TABLE IF EXISTS [aux_flag2trigger_updateReminderMsgs];
DROP TABLE IF EXISTS [aux_senderEmails];

DROP TABLE IF EXISTS [output_finalValidGroups];
DROP TABLE IF EXISTS [output_conflictingGroups];
DROP TABLE IF EXISTS [output_nonAgreedGroups];
DROP TABLE IF EXISTS [output_lengthExceededGroups];
DROP TABLE IF EXISTS [output_reminderMsgs];

DROP TABLE IF EXISTS [input_userApplications];
DROP TABLE IF EXISTS [input_groupLengthLimit];
DROP TABLE IF EXISTS [input_generateGroupReports];

DROP TRIGGER IF EXISTS trigger_getMaybeRollNos;
DROP TRIGGER IF EXISTS trigger_getApplicationInfo;
DROP TRIGGER IF EXISTS trigger_insertMaybeGroupDetails;
DROP TRIGGER IF EXISTS trigger_validateCurrentGroup;
DROP TRIGGER IF EXISTS trigger_insertCurrentGroupMemberGIds;
DROP TRIGGER IF EXISTS trigger_updateGroupMemberAgreementStatus;
DROP TRIGGER IF EXISTS trigger_checkIfGroupMembersAgree;
DROP TRIGGER IF EXISTS trigger_updateReminderMsgs;
DROP TRIGGER IF EXISTS trigger_generateGroupReports;


CREATE TABLE [input_groupLengthLimit]
(
    [id] INTEGER AUTO INCREMENT,
    [length] TEXT NOT NULL,
    CONSTRAINT [PKC_input_groupLengthLimit] PRIMARY KEY ([id])
);

CREATE TABLE [input_userApplications]
(
    [msg] TEXT NOT NULL,
    [senderEmail] TEXT NOT NULL,
    CONSTRAINT [PKC_input_userApplications] PRIMARY KEY ([msg],[senderEmail])
);

CREATE TABLE [input_generateGroupReports]
(
    [val] TEXT PRIMARY KEY
);

CREATE TABLE [aux_senderEmails]
(
    [senderEmailId] TEXT PRIMARY KEY
);

CREATE TABLE [aux_maybeRollNos]
(
    [remainingMemberRollString] TEXT PRIMARY KEY
);

CREATE TABLE [aux_userApplicationInfo]
(
    [msgId] INTEGER PRIMARY KEY AUTOINCREMENT,
    [senderRollNo] TEXT  NOT NULL,
    [senderEmailId] TEXT  NOT NULL,
    [timestamp] TEXT NOT NULL,
    [validationResult] TEXT DEFAULT 'invalid',

    CONSTRAINT [CHKinput_userApplications] CHECK ([validationResult] in ('valid', 'invalid'))
    FOREIGN KEY ([senderEmailId]) REFERENCES [aux_senderEmails] ([senderEmailId])
    ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE [aux_maybeGroups]
(
    [groupId] TEXT NOT NULL,
    [timestamp] TEXT  NOT NULL,
    [senderRollNo] TEXT NOT NULL,
    [senderEmailId] TEXT NOT NULL,

    CONSTRAINT [PKC_aux_maybeGroups] PRIMARY KEY  ([groupId],[senderRollNo])
    FOREIGN KEY ([senderEmailId]) REFERENCES [aux_senderEmails] ([senderEmailId])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [aux_maybeGroupMembers]
(
    [groupId] TEXT NOT NULL,
    [senderRollNo] TEXT  NOT NULL,
    [memberRollNo] TEXT NOT NULL,
    [agreementStatus] TEXT NOT NULL default 'No',

    CONSTRAINT [PKC_aux_maybeGroupMembers] PRIMARY KEY ([groupId],[senderRollNo],[memberRollNo]),
    CONSTRAINT [CHK_agreementStatus] CHECK ([agreementStatus] in ('Yes','No')),
    FOREIGN KEY ([groupId],[senderRollNo]) REFERENCES [aux_maybeGroups] ([groupId],[senderRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [aux_currentGroupMembersRollNos]
(
    [groupId] TEXT NOT NULL,
    [senderRollNo] TEXT  NOT NULL,
    [memberRollNo] TEXT NOT NULL,

    CONSTRAINT [PKC_currentGroupMembers] PRIMARY KEY ([groupId],[senderRollNo],[memberRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo],[memberRollNo]) REFERENCES [aux_maybeGroupMembers] ([groupId],[senderRollNo],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [aux_currentGroupMembersGIds]
(
    [groupId] TEXT NOT NULL,
    [senderRollNo] TEXT  NOT NULL,

    CONSTRAINT [PKC_groupId] PRIMARY KEY ([groupId],[senderRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo]) REFERENCES [aux_maybeGroups] ([groupId],[senderRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [aux_agreedGroups]
(
    [finalGId] TEXT NOT NULL,
    [groupId] TEXT NOT NULL,
    [memberRollNo] TEXT NOT NULL,
    CONSTRAINT [PKC_aux_agreedGroups] PRIMARY KEY ([finalGId],[groupId],[memberRollNo])
);

CREATE TABLE [aux_maybeMemberRollNos]
(
    [memberRollNo] TEXT PRIMARY KEY
);

CREATE TABLE [aux_flag2trigger_checkIfGroupMembersAgree]
(
    [val] TEXT PRIMARY KEY
);

CREATE TABLE [aux_flag2trigger_updateReminderMsgs]
(
    [val] TEXT PRIMARY KEY
);

CREATE TABLE [output_finalValidGroups]
(
    [finalGId] TEXT NOT NULL,
    [groupId] TEXT NOT NULL,
    [memberRollNo] TEXT NOT NULL,

    CONSTRAINT [PKC_output_finalValidGroups] PRIMARY KEY ([finalGId],[groupId],[memberRollNo]),
    FOREIGN KEY ([finalGId],[groupId],[memberRollNo]) REFERENCES [aux_agreedGroups] ([finalGId],[groupId],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [output_nonAgreedGroups]
(
    [groupId] TEXT NOT NULL,
    [senderRollNo] TEXT NOT NULL,
    CONSTRAINT [PKC_output_nonAgreedGroups] PRIMARY KEY ([groupId],[senderRollNo]),
    FOREIGN KEY ([groupId],[senderRollNo]) REFERENCES [aux_maybeGroups] ([groupId],[senderRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [output_conflictingGroups]
(
    [finalGId] TEXT NOT NULL,
    [groupId] TEXT NOT NULL,
    [memberRollNo] TEXT NOT NULL,
    CONSTRAINT [PKC_output_conflictingGroups] PRIMARY KEY ([finalGId],[groupId],[memberRollNo])
    FOREIGN KEY ([finalGId],[groupId],[memberRollNo]) REFERENCES [aux_agreedGroups] ([finalGId],[groupId],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [output_lengthExceededGroups]
(
    [finalGId] TEXT NOT NULL,
    [groupId] TEXT NOT NULL,
    [memberRollNo] TEXT NOT NULL,
    CONSTRAINT [PKC_lengthExceededGroup] PRIMARY KEY ([finalGId],[groupId],[memberRollNo])
    FOREIGN KEY ([finalGId],[groupId],[memberRollNo]) REFERENCES [aux_agreedGroups] ([finalGId],[groupId],[memberRollNo])
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE [output_reminderMsgs]
(
    [groupId] TEXT NOT NULL,
    [senderRollNo] TEXT NOT NULL,
    [senderEmailId] TEXT NOT NULL,
    [msg] TEXT NOT NULL,
    CONSTRAINT [PKC_reminderMsgs] PRIMARY KEY ([groupId],[senderRollno]),
    FOREIGN KEY ([groupId],[senderRollno]) REFERENCES [aux_maybeGroups] ([groupId],[senderRollno])
    ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TRIGGER trigger_getApplicationInfo after insert on input_userApplications
  begin
    delete from aux_maybeRollNos;
    delete from aux_maybeMemberRollNos;
    delete from aux_currentGroupMembersRollNos;
    delete from aux_currentGroupMembersGIds;
    delete from aux_flag2trigger_checkIfGroupMembersAgree;
    insert into aux_senderEmails values(new.senderEmail);
    insert into aux_maybeRollNos select substr(new.msg,(select instr(new.msg,' ')+1));
    insert into aux_userApplicationInfo(senderRollNo,senderEmailId,timestamp,validationResult) values ((select substr(new.msg,1,(select instr(new.msg,' ')-1))),new.senderEmail,datetime('now'),'valid');
  end;

CREATE TRIGGER trigger_getMaybeRollNos after insert on aux_maybeRollNos
when (select length(new.remainingMemberRollString)) > 0
  begin
    insert into aux_maybeMemberRollNos select substr(new.remainingMemberRollString,1,(select instr(new.remainingMemberRollString,' ')-1));
    insert into aux_maybeRollNos select substr(new.remainingMemberRollString,(select instr(new.remainingMemberRollString,' ')+1));
  end;

CREATE TRIGGER trigger_insertMaybeGroupDetails after insert on aux_userApplicationInfo
when new.validationResult='valid'
  begin
    insert into aux_maybeGroups values(new.msgId,new.timestamp,new.senderRollNo,new.senderEmailId);
  end;


CREATE TRIGGER trigger_validateCurrentGroup after insert on aux_maybeGroups
begin
    insert into aux_maybeGroupMembers (groupId,senderRollNo,memberRollNo) select * from (select groupId,senderRollNo from aux_maybeGroups where groupId =new.groupId) inner join aux_maybeMemberRollNos;
    insert into aux_currentGroupMembersRollNos select groupId,senderRollNo,memberRollNo from aux_maybeGroupMembers where groupId = new.groupId;
    insert into aux_currentGroupMembersGIds values (new.groupId,new.senderRollNo);
    insert into aux_flag2trigger_checkIfGroupMembersAgree values ('1');
    insert into aux_flag2trigger_updateReminderMsgs values ('1');
end;

CREATE TRIGGER trigger_updateGroupMemberAgreementStatus after insert on aux_maybeGroupMembers
when (select count(*) from aux_maybeGroupMembers where agreementStatus='No' and senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo) >0
begin
    update aux_maybeGroupMembers set agreementStatus='Yes' where groupId=new.groupId and senderRollNo=new.senderRollNo and memberRollNo=new.memberRollNo;
    update aux_maybeGroupMembers set agreementStatus='Yes' where  senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo;
end;

CREATE TRIGGER trigger_insertCurrentGroupMemberGIds after insert on aux_currentGroupMembersRollNos
begin
    insert into aux_currentGroupMembersGIds select groupId,senderRollNo from aux_maybeGroupMembers where senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo;
end;


create trigger trigger_checkIfGroupMembersAgree after insert on aux_flag2trigger_checkIfGroupMembersAgree
when (select count(agreementStatus) from aux_maybeGroupMembers where groupId in (select groupId from aux_currentGroupMembersGIds) and agreementStatus='No') = 0
begin
    insert into aux_agreedGroups  select * from ((select group_concat(groupId,'') from aux_currentGroupMembersGIds) inner join aux_currentGroupMembersGIds);
end;

create trigger trigger_updateReminderMsgs after insert on aux_flag2trigger_updateReminderMsgs
begin
    delete from aux_flag2trigger_updateReminderMsgs;
    delete from output_reminderMsgs where groupId in (select groupId from aux_currentGroupMembersGIds);
    insert into output_reminderMsgs select * from (select groupId,senderRollNo,senderEmailId,'No application got in favour of -> '||sroll||' from '||mrolls from aux_maybeGroups inner join (select groupId as gid,senderRollNo as sroll,group_concat(memberRollNo) as mrolls from aux_maybeGroupMembers where agreementstatus='No' and groupId in (select groupId from aux_currentGroupMembersGIds) group by groupid) where sroll=senderRollno and gid=aux_maybeGroups.groupId);
end;

CREATE TRIGGER trigger_generateGroupReports after insert on input_generateGroupReports
begin
    delete from input_generateGroupReports;
    delete from output_nonAgreedGroups;
    delete from output_conflictingGroups;
    delete from output_lengthExceededGroups;
    delete from output_finalValidGroups;

    insert into output_nonAgreedGroups select distinct groupId,senderRollNo from aux_maybeGroupMembers where agreementStatus='No';

    insert into output_conflictingGroups select * from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups where memberRollNo in (select memberRollNo from aux_agreedGroups group by memberRollNo having count(*)>1));

    insert into output_lengthExceededGroups select * from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups group by finalGId having count(memberRollNo) > (select length from input_groupLengthLimit order by id desc limit 1));

    insert into output_finalValidGroups select * from aux_agreedGroups where finalGId not in (select finalGId from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups where memberRollNo in (select memberRollNo from aux_agreedGroups group by memberRollNo having count(*)>1))) and finalGId not in (select finalGId from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups group by finalGId having count(memberRollNo) > (select length from input_groupLengthLimit order by id desc limit 1)));

end;


insert into input_userApplications values('13 49 19 ','yhty@gmail.com');
insert into input_userApplications values('19 49 13 ','sknn@gmail.com');
insert into input_userApplications values('49 13 19 ','etgt@gmail.com');

insert into input_userApplications values('50 ','setgt@gmail.com');
insert into input_userApplications values('52 64 ','ssaetgt@gmail.com');

insert into input_userApplications values('41 50 90 ','ewwwtgt@gmail.com');


insert into input_userApplications values('1 2 3 4 ','daetgt@gmail.com');
insert into input_userApplications values('2 1 3 4 ','edatgt@gmail.com');
insert into input_userApplications values('3 2 1 4 ','wdtgt@gmail.com');
insert into input_userApplications values('4 2 3 1 ','detgt@gmail.com');


insert into input_userApplications values('5 6 7 ','qetgt@gmail.com');
insert into input_userApplications values('7 6 5 ','wetgt@gmail.com');
insert into input_userApplications values('6 5 7 ','eetgt@gmail.com');

insert into input_userApplications values('15 16 7 ','retgt@gmail.com');
insert into input_userApplications values('7 16 15 ','tetgt@gmail.com');
insert into input_userApplications values('16 15 7 ','yetgt@gmail.com');


insert into input_groupLengthLimit(length) values(3);


insert into input_generateGroupReports values(1);

end;
select 'output_nonAgreedGroups';
select * from output_nonAgreedGroups;
select 'output_conflictingGroups';
select * from output_conflictingGroups where memberrollno in (select memberRollNo from output_conflictingGroups group by memberRollNo having count()>1);
select 'output_lengthExceededGroups';
select * from output_lengthExceededGroups;
select 'output_finalValidGroups';
select * from output_finalValidGroups;
select 'output_reminderMsgs';
select * from output_reminderMsgs;

