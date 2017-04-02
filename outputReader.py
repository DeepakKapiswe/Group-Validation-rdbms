import sys
import MySQLdb as m
import ConfigParser
import time

configParser=ConfigParser.RawConfigParser()
configFilePath=r'database.config'
configParser.read(configFilePath)

user=configParser.get('section','user')
userPassword=configParser.get('section','userPassword')
databaseName=configParser.get('section','databaseName')

def connectToDB():
    return m.connect("localhost",user,userPassword,databaseName)

def disconnectFromDb(connectionName):
    return connectionName.close()

def makeHTMLTableRow(record):
    return "<tr><td>"+record[2]+"</td><td>"+record[3]+"</td></tr>"

frontPart='<html><head><center><h1><b><u> Reminder Msgs </h1></center></head><center><table border="1"><tr><th>Sender Email</th><th>Response</th></tr>'
lastPart='</table></center></html>'

def makeResponseHTML(results):
    rows=''.join([makeHTMLTableRow(x) for x in results])
    return frontPart+rows+lastPart

def writeFile(fname,fileString):
    return open(fname,"w").write(fileString)

def writeResponseFile(fname):
    conn=connectToDB()
    cur=conn.cursor()
    cur.execute('select * from output_reminderMsgs')
    result = cur.fetchall()
    if result != 0:
        writeFile(fname,makeResponseHTML(result))
    disconnectFromDb(conn)
    return

while True:
    writeResponseFile(sys.argv[1])
    time.sleep(7)

