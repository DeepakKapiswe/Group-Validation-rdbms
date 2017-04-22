/*

foreign/primary key errors to be handled after changing to mysql

reminders be generated on trigger
time consideration
*/

DROP DATABASE IF EXISTS groupdb;
CREATE DATABASE groupdb;
USE groupdb;

DROP TABLE IF EXISTS output_finalValidGroups;
DROP TABLE IF EXISTS output_conflictingGroups;
DROP TABLE IF EXISTS output_nonAgreedGroups;
DROP TABLE IF EXISTS output_lengthExceededGroups;
DROP TABLE IF EXISTS output_reminderMsgs;

DROP TABLE IF EXISTS aux_userApplicationInfo;
DROP TABLE IF EXISTS aux_currentGroupMembersGIds;
DROP TABLE IF EXISTS aux_currentGroupMembersRollNos;
DROP TABLE IF EXISTS aux_agreedGroups;
DROP TABLE IF EXISTS aux_maybeGroupMembers;
DROP TABLE IF EXISTS aux_helperForTrigger_updateGroupMemberAgreementStatus;
DROP TABLE IF EXISTS aux_maybeGroups;
DROP TABLE IF EXISTS aux_maybeRollNos;
DROP TABLE IF EXISTS aux_maybeMemberRollNos;
DROP TABLE IF EXISTS aux_flag2trigger_checkIfGroupMembersAgree;
DROP TABLE IF EXISTS aux_flag2trigger_updateReminderMsgs;
DROP TABLE IF EXISTS aux_senderEmails;


DROP TABLE IF EXISTS input_userApplications;
DROP TABLE IF EXISTS input_groupLengthLimit;
DROP TABLE IF EXISTS input_userFormSubmissionDeadline;
DROP TABLE IF EXISTS input_generateGroupReports;

DROP TRIGGER IF EXISTS trigger_insertCurrentTime;
DROP TRIGGER IF EXISTS trigger_getMaybeRollNos;
DROP TRIGGER IF EXISTS trigger_getApplicationInfo;
DROP TRIGGER IF EXISTS trigger_insertMaybeGroupDetails;
DROP TRIGGER IF EXISTS trigger_validateCurrentGroup;
DROP TRIGGER IF EXISTS trigger_insertCurrentGroupMemberGIds;
DROP TRIGGER IF EXISTS trigger_updateGroupMemberAgreementStatus;
DROP TRIGGER IF EXISTS trigger_checkIfGroupMembersAgree;
DROP TRIGGER IF EXISTS trigger_updateReminderMsgs;
DROP TRIGGER IF EXISTS trigger_generateGroupReports;

DROP PROCEDURE IF EXISTS procedure_getMaybeRollNos;

CREATE TABLE input_groupLengthLimit
(
    id INTEGER AUTO_INCREMENT,
    length TEXT NOT NULL,
    CONSTRAINT PKC_input_groupLengthLimit PRIMARY KEY (id)
);

CREATE TABLE input_userFormSubmissionDeadline
(
    id INTEGER AUTO_INCREMENT PRIMARY KEY,
    deadline TEXT NOT NULL
);

CREATE TABLE input_userApplications
(
    msgId INTEGER AUTO_INCREMENT,
    msg TEXT NOT NULL,
    senderEmail TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PKC_input_userApplications PRIMARY KEY (msgId)
);

CREATE TABLE input_generateGroupReports
(
    val VARCHAR(5) NOT NULL
);

CREATE TABLE aux_senderEmails
(
    senderEmailId VARCHAR(255) PRIMARY KEY
);

CREATE TABLE aux_maybeRollNos
(
    id INTEGER AUTO_INCREMENT PRIMARY KEY,
    remainingMemberRollString TEXT
);

CREATE TABLE aux_userApplicationInfo
(
    msgId INTEGER PRIMARY KEY AUTO_INCREMENT,
    senderRollNo TEXT  NOT NULL,
    senderEmailId VARCHAR (255)  NOT NULL,
    timestamp TEXT NOT NULL,
    validationResult VARCHAR (8) DEFAULT 'invalid',

    CONSTRAINT CHKaux_userApplicationInfo CHECK (validationResult in ('valid', 'invalid')),
    FOREIGN KEY (senderEmailId) REFERENCES aux_senderEmails (senderEmailId)
    ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE aux_maybeGroups
(
    groupId INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    senderRollNo VARCHAR (10) NOT NULL,
    senderEmailId VARCHAR (255) NOT NULL,

    CONSTRAINT PKC_aux_maybeGroups PRIMARY KEY (groupId,senderRollNo),
    FOREIGN KEY (senderEmailId) REFERENCES aux_senderEmails (senderEmailId)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE aux_maybeGroupMembers
(
    groupId INTEGER NOT NULL,
    senderRollNo VARCHAR (10)  NOT NULL,
    memberRollNo VARCHAR (10) NOT NULL,
    agreementStatus VARCHAR (4) NOT NULL default 'No',

    CONSTRAINT PKC_aux_maybeGroupMembers PRIMARY KEY (groupId,senderRollNo,memberRollNo),
    CONSTRAINT CHK_agreementStatus CHECK (agreementStatus in ('Yes','No')),
    FOREIGN KEY (groupId,senderRollNo) REFERENCES aux_maybeGroups (groupId,senderRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE aux_helperForTrigger_updateGroupMemberAgreementStatus
(
    groupId INTEGER NOT NULL,
    senderRollNo VARCHAR (10)  NOT NULL,
    memberRollNo VARCHAR (10) NOT NULL,
    CONSTRAINT PKC_aux_maybeGroupMembers PRIMARY KEY (groupId,senderRollNo,memberRollNo),
    FOREIGN KEY (groupId,senderRollNo) REFERENCES aux_maybeGroups (groupId,senderRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE aux_currentGroupMembersRollNos
(
    groupId INTEGER NOT NULL,
    senderRollNo VARCHAR (10)  NOT NULL,
    memberRollNo VARCHAR (10) NOT NULL,

    CONSTRAINT PKC_currentGroupMembers PRIMARY KEY (groupId,senderRollNo,memberRollNo),
    FOREIGN KEY (groupId,senderRollNo,memberRollNo) REFERENCES aux_maybeGroupMembers (groupId,senderRollNo,memberRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE aux_currentGroupMembersGIds
(
    groupId INTEGER NOT NULL,
    senderRollNo VARCHAR (10)  NOT NULL,

    CONSTRAINT PKC_groupId PRIMARY KEY (groupId,senderRollNo),
    FOREIGN KEY (groupId,senderRollNo) REFERENCES aux_maybeGroups (groupId,senderRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE aux_agreedGroups
(
    finalGId VARCHAR (255) NOT NULL,
    groupId INTEGER NOT NULL,
    memberRollNo VARCHAR (10) NOT NULL,
    CONSTRAINT PKC_aux_agreedGroups PRIMARY KEY (finalGId,groupId,memberRollNo)
);

CREATE TABLE aux_maybeMemberRollNos
(
    memberRollNo VARCHAR (10) PRIMARY KEY
);

CREATE TABLE aux_flag2trigger_checkIfGroupMembersAgree
(
    val VARCHAR (5) PRIMARY KEY
);

CREATE TABLE aux_flag2trigger_updateReminderMsgs
(
    val VARCHAR (5) PRIMARY KEY
);

CREATE TABLE output_finalValidGroups
(
    finalGId VARCHAR (255) NOT NULL,
    groupId INTEGER NOT NULL,
    memberRollNo VARCHAR (10) NOT NULL,

    CONSTRAINT PKC_output_finalValidGroups PRIMARY KEY (finalGId,groupId,memberRollNo),
    FOREIGN KEY (finalGId,groupId,memberRollNo) REFERENCES aux_agreedGroups (finalGId,groupId,memberRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE output_nonAgreedGroups
(
    groupId INTEGER NOT NULL,
    senderRollNo VARCHAR (10) NOT NULL,
    CONSTRAINT PKC_output_nonAgreedGroups PRIMARY KEY (groupId,senderRollNo),
    FOREIGN KEY (groupId,senderRollNo) REFERENCES aux_maybeGroups (groupId,senderRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE output_conflictingGroups
(
    finalGId VARCHAR (255) NOT NULL,
    groupId INTEGER NOT NULL,
    memberRollNo VARCHAR (10) NOT NULL,
    CONSTRAINT PKC_output_conflictingGroups PRIMARY KEY (finalGId,groupId,memberRollNo),
    FOREIGN KEY (finalGId,groupId,memberRollNo) REFERENCES aux_agreedGroups (finalGId,groupId,memberRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE output_lengthExceededGroups
(
    finalGId VARCHAR (255) NOT NULL,
    groupId INTEGER NOT NULL,
    memberRollNo VARCHAR (10) NOT NULL,
    CONSTRAINT PKC_lengthExceededGroup PRIMARY KEY (finalGId,groupId,memberRollNo),
    FOREIGN KEY (finalGId,groupId,memberRollNo) REFERENCES aux_agreedGroups (finalGId,groupId,memberRollNo)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE output_lateSubmissions
(
    senderRollNo VARCHAR (10)  NOT NULL,
    senderEmailId VARCHAR (255) NOT NULL,
    msg TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    CONSTRAINT PKC_output_lateSubmissions PRIMARY KEY (senderRollno,timestamp)
    /*FOREIGN KEY (senderEmailId) REFERENCES aux_senderEmails (senderEmailId)
    ON DELETE RESTRICT ON UPDATE CASCADE*/
);

CREATE TABLE output_reminderMsgs
(
    groupId INTEGER NOT NULL,
    senderRollNo VARCHAR (10) NOT NULL,
    senderEmailId VARCHAR (255) NOT NULL,
    msg TEXT NOT NULL,
    CONSTRAINT PKC_reminderMsgs PRIMARY KEY (groupId,senderRollno),
    FOREIGN KEY (groupId,senderRollno) REFERENCES aux_maybeGroups (groupId,senderRollno)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

delimiter |

CREATE TRIGGER trigger_getApplicationInfo after insert on input_userApplications
FOR EACH ROW
  begin
    if new.timestamp < (select deadline from input_userFormSubmissionDeadline order by id desc limit 1)
      then
    delete from aux_maybeRollNos;
    delete from aux_maybeMemberRollNos;
    delete from aux_currentGroupMembersRollNos;
    delete from aux_currentGroupMembersGIds;
    delete from aux_flag2trigger_checkIfGroupMembersAgree;
    insert into aux_senderEmails values(new.senderEmail);
    call procedure_getMaybeRollNos((select substr(new.msg,(select instr(new.msg,' ')+1))));
    insert into aux_userApplicationInfo (senderRollNo,senderEmailId,timestamp,validationResult) values ((select substr(new.msg,1,(select instr(new.msg,' ')-1))),new.senderEmail,new.timestamp,'valid');
  else
    insert into output_lateSubmissions values ((select substr(new.msg,1,(select instr(new.msg,' ')-1))),new.senderEmail,new.msg,new.timestamp);
    end if;
  end;

CREATE TRIGGER trigger_insertMaybeGroupDetails after insert on aux_userApplicationInfo
FOR EACH ROW
  begin
    declare oldGid INTEGER;
    declare oldfinalGid INTEGER;
    if new.validationResult='valid'
      then
    set oldGid = (select groupId from aux_maybeGroups where senderRollNo=new.senderRollNo);
    set oldfinalGId = (select finalGId from aux_agreedGroups where groupId =oldGid);
    update aux_maybeGroupMembers set agreementStatus='No' where memberRollNo=new.senderRollNo;
    delete from aux_agreedGroups where finalGId =oldfinalGId;
    delete from aux_maybeGroupMembers where groupId=oldGid;
    delete from aux_maybeGroups where groupId=oldGid;
    insert into aux_maybeGroups values(new.msgId,new.timestamp,new.senderRollNo,new.senderEmailId);
    end if;
  end;

CREATE TRIGGER trigger_validateCurrentGroup after insert on aux_maybeGroups
FOR EACH ROW
begin
    insert into aux_maybeGroupMembers (groupId,senderRollNo,memberRollNo) select amg.groupId,amg.senderRollNo,ammr.memberRollNo from aux_maybeGroups as amg inner join aux_maybeMemberRollNos as ammr where amg.groupId =new.groupId;
    delete from aux_helperForTrigger_updateGroupMemberAgreementStatus;
    insert into aux_helperForTrigger_updateGroupMemberAgreementStatus (groupId,senderRollNo,memberRollNo) select amg.groupId,amg.senderRollNo,ammr.memberRollNo from aux_maybeGroups as amg inner join aux_maybeMemberRollNos as ammr where amg.groupId =new.groupId;
    insert into aux_currentGroupMembersRollNos select groupId,senderRollNo,memberRollNo from aux_maybeGroupMembers where groupId = new.groupId;
    insert into aux_currentGroupMembersGIds values (new.groupId,new.senderRollNo);
    delete from aux_flag2trigger_checkIfGroupMembersAgree;
    insert into aux_flag2trigger_checkIfGroupMembersAgree values ('1');
    delete from aux_flag2trigger_updateReminderMsgs;
    insert into aux_flag2trigger_updateReminderMsgs values ('1');
end;

CREATE TRIGGER trigger_updateGroupMemberAgreementStatus after insert on aux_helperForTrigger_updateGroupMemberAgreementStatus
FOR EACH ROW
begin
 if (select count(*) from aux_maybeGroupMembers where agreementStatus='No' and senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo) >0
 then
    update aux_maybeGroupMembers set agreementStatus='Yes' where groupId=new.groupId and senderRollNo=new.senderRollNo and memberRollNo=new.memberRollNo;
    update aux_maybeGroupMembers set agreementStatus='Yes' where  senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo;
 end if;
end;

CREATE TRIGGER trigger_insertCurrentGroupMemberGIds after insert on aux_currentGroupMembersRollNos
FOR EACH ROW
begin
    insert into aux_currentGroupMembersGIds select groupId,senderRollNo from aux_maybeGroupMembers where senderRollNo=new.memberRollNo and memberRollNo=new.senderRollNo;
end;

create trigger trigger_checkIfGroupMembersAgree after insert on aux_flag2trigger_checkIfGroupMembersAgree
FOR EACH ROW
begin
  if (select count(agreementStatus) from aux_maybeGroupMembers where groupId in (select groupId from aux_currentGroupMembersGIds) and agreementStatus='No') = 0
    then
    insert into aux_agreedGroups select fgids.*,acgmg.* from (select group_concat(groupId separator '') from aux_currentGroupMembersGIds) as fgids inner join aux_currentGroupMembersGIds as acgmg;
  end if;
end;

create trigger trigger_updateReminderMsgs after insert on aux_flag2trigger_updateReminderMsgs
FOR EACH ROW
begin
    delete from output_reminderMsgs where groupId in (select groupId from aux_currentGroupMembersGIds);

    insert into output_reminderMsgs select t.* from (select mg.groupId,mg.senderRollNo,mg.senderEmailId,concat('No application got in favour of -> ',t1.sroll,' from ',t1.mrolls) from aux_maybeGroups as mg inner join (select mgm.groupId as gid,mgm.senderRollNo as sroll,group_concat(mgm.memberRollNo) as mrolls from aux_maybeGroupMembers as mgm where mgm.agreementstatus='No' and mgm.groupId in (select cgmg.groupId from aux_currentGroupMembersGIds as cgmg) group by mgm.groupid) as t1 where t1.sroll=mg.senderRollno and t1.gid=mg.groupId) as t;

end;

CREATE TRIGGER trigger_generateGroupReports after insert on input_generateGroupReports
FOR EACH ROW
begin
    delete from output_nonAgreedGroups;
    delete from output_conflictingGroups;
    delete from output_lengthExceededGroups;
    delete from output_finalValidGroups;

    insert into output_nonAgreedGroups select distinct groupId,senderRollNo from aux_maybeGroupMembers where agreementStatus='No';

    insert into output_conflictingGroups select * from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups where memberRollNo in (select memberRollNo from aux_agreedGroups group by memberRollNo having count(*)>1));

    insert into output_lengthExceededGroups select * from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups group by finalGId having count(memberRollNo) > (select length from input_groupLengthLimit order by id desc limit 1));

    insert into output_finalValidGroups select * from aux_agreedGroups where finalGId not in (select finalGId from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups where memberRollNo in (select memberRollNo from aux_agreedGroups group by memberRollNo having count(*)>1))) and finalGId not in (select finalGId from aux_agreedGroups where finalGId in (select finalGId from aux_agreedGroups group by finalGId having count(memberRollNo) > (select length from input_groupLengthLimit order by id desc limit 1)));
end;

CREATE PROCEDURE procedure_getMaybeRollNos (inputString TEXT)
  begin
    declare remainingMemberRollString TEXT;
    set remainingMemberRollString =inputString;
    while (select length(remainingMemberRollString)) > 0
      do
        insert into aux_maybeMemberRollNos  select substr(remainingMemberRollString,1,(select instr(remainingMemberRollString,' ')-1));
        set remainingMemberRollString = (select substr(remainingMemberRollString,(select instr(remainingMemberRollString,' ')+1)));
    end while;
  end;
 |
delimiter ;
/*
insert into input_userFormSubmissionDeadline(deadline) values ('2017-04-29 03:42:14');

insert into input_userApplications(msg,senderEmail,timestamp) values('100 110 120 ','lkj@gmail.com','2017-05-29 03:42:14');
insert into input_userApplications(msg,senderEmail,timestamp) values('13 49 19 ','yhty@gmail.com','2017-05-29 03:42:14');
insert into input_userApplications(msg,senderEmail,timestamp) values('19 49 13 ','sknn@gmail.com',current_timestamp());
insert into input_userApplications (msg,senderEmail,timestamp) values('49 13 19 ','etgt@gmail.com',current_timestamp());
insert into input_userApplications (msg,senderEmail,timestamp) values('50 ','setgt@gmail.com',current_timestamp());
insert into input_userApplications (msg,senderEmail,timestamp) values('52 64 ','ssaetgt@gmail.com',current_timestamp());

insert into input_userApplications(msg,senderEmail,timestamp)  values('41 50 90 ','ewwwtgt@gmail.com',current_timestamp());


insert into input_userApplications (msg,senderEmail,timestamp) values('1 2 3 4 ','daetgt@gmail.com',current_timestamp());
insert into input_userApplications(msg,senderEmail,timestamp)  values('2 1 3 4 ','edatgt@gmail.com',current_timestamp());
insert into input_userApplications(msg,senderEmail,timestamp)  values('3 2 1 4 ','wdtgt@gmail.com',current_timestamp());
insert into input_userApplications(msg,senderEmail,timestamp)  values('4 2 3 1 ','detgt@gmail.com',current_timestamp());


insert into input_userApplications (msg,senderEmail,timestamp) values('5 6 7 ','qetgt@gmail.com',current_timestamp());
insert into input_userApplications(msg,senderEmail,timestamp)  values('7 6 5 ','wetgt@gmail.com',current_timestamp());
insert into input_userApplications (msg,senderEmail,timestamp) values('6 5 7 ','eetgt@gmail.com',current_timestamp());

insert into input_userApplications (msg,senderEmail,timestamp) values('15 16 7 ','retgt@gmail.com',current_timestamp());
insert into input_userApplications (msg,senderEmail,timestamp) values('7 16 15 ','tetgt@gmail.com',current_timestamp());
insert into input_userApplications (msg,senderEmail,timestamp) values('16 15 7 ','yetgt@gmail.com',current_timestamp());


delete from input_generateGroupReports;
insert into input_groupLengthLimit(length) values(3);


insert into input_generateGroupReports values('1');
select 'output_nonAgreedGroups';
select * from output_nonAgreedGroups;
select 'output_conflictingGroups';
select * from output_conflictingGroups where memberrollno in (select memberRollNo from output_conflictingGroups group by memberRollNo having count(*)>1);
select 'output_lengthExceededGroups';
select * from output_lengthExceededGroups;
select 'output_finalValidGroups';
select * from output_finalValidGroups;
select 'output_reminderMsgs';
select * from output_reminderMsgs;
select 'output_lateSubmissions';
select * from output_lateSubmissions;
*/
