import MySQLdb as m
import ConfigParser
import time


def feedData(dataList,sleepTime,cursor):
    for i in range(len(dataList)):
        insertStatement='insert into input_userApplications(msg,senderEmail,timestamp) values ("'+dataList[i][0]+'","'+dataList[i][1]+'","0")'
        cur.execute(insertStatement)
        conn.commit()
        time.sleep(sleepTime)
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


inputUserApplications=map(lambda x:((x[0]).strip()+' ',x[1]),[(x.strip()).split(',') for x in open("userApplications.data","r").readlines()])


cur.execute('insert into input_groupLengthLimit(length) values(%s)',maxGroupLength)
cur.execute('insert into input_userFormSubmissionDeadline(deadline) values (%s)',deadline)

feedData(inputUserApplications,7,cur)
conn.close()

