import MySQLdb as m
import ConfigParser


def feedData(dataList,sleepingTime,cursor):
    for i in range(len(dataList)):
        cursor.execute('insert into input_userApplications(msg,senderEmail,timestamp) values(%s,%s,"0")',(dataList[i][0],dataList[i][1]))
    return

configParser=ConfigParser.RawConfigParser()
configFilePath=r'database.config'
configParser.read(configFilePath)

user=configParser.get('section','user')
userPassword=configParser.get('section','userPassword')
databaseName=configParser.get('section','databaseName')


conn=m.connect("localhost",user,userPassword,databaseName)
cur=conn.cursor()



configFilePath=r'userGroupValidation.Config'
configParser.read(configFilePath)
maxGroupLength=configParser.get('section','maxGroupLength')
deadline=configParser.get('section','deadline')


inputUserApplications=[(x.strip()).split(',') for x in open("userApplications.data","r").readlines()]


cur.execute('insert into input_groupLengthLimit(length) values(%s)',maxGroupLength)
cur.execute('insert into input_userFormSubmissionDeadline(deadline) values (%s)',deadline)

cur.execute('select * from input_userFormSubmissionDeadline')
a=cur.fetchall()
feedData(inputUserApplications,1.2,cur)
a=cur.fetchall()
conn.commit()
conn.close()

#insert into input_userApplications(msg,senderEmail,timestamp) values('13 49 19 ','yhty@gmail.com','2017-05-29 03:42:14');
