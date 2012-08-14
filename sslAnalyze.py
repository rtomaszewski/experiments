
import sys, getopt, string
import commands
import re
#import pickle
#import json
import simplejson as json
import datetime
import time

#1000 microseconds = 1 millisecond
#1 second = 1000 milliseconds
#0.01 seconds = 10 milliseconds
#10 milliseconds = 10 000 microseconds

DEBUG=0

class SslAnalyze:
    tcpdumpList = []
    timeList = []
    printHeader = True

    sslConnMax= 10
    sslConnHighFile= "sslConnHigh.txt"

    #FH = None

    def init(self):
        self.FH = open('./' + self.sslConnHighFile, 'a+')

    def print_debug(sefl, str, debug=DEBUG):
        if debug == 1:
            print "DEBUG: " + str
                
    def highTpsInProbeTime(self, timestamp, probeList, mikrosecond):
        probeCount=1000000/mikrosecond
        self.print_debug("highTpsInProbeTim start")
        
        dateAux=datetime.datetime.fromtimestamp( timestamp )
        
        sum=0
        for i in probeList:
            sum+=i

        secondAux=str(probeCount)                
        self.FH.write( "%25s %13s %13s " % ( dateAux.ctime() , str(timestamp), " sum:" + str(sum)) )

        tmp=0 
        while tmp<probeCount:
            self.FH.write("%4d" % ( probeList[tmp] ))
            tmp+=1
        self.FH.write("\n")
                
    def showRow(self, timestamp, probeList,mikrosecond):
        isHighValue=False
        probeCount=1000000/mikrosecond

        self.print_debug("showRow start")
        self.print_debug("timestamp " + json.dumps(timestamp))
        self.print_debug("sslConnMax " + str(self.sslConnMax))
        self.print_debug(json.dumps(probeList))
        
        #timeAux=time.localtime(timestamp)
        dateAux=datetime.datetime.fromtimestamp( timestamp )
        sum=0
        for i in probeList:
            self.print_debug("i " + str(i) + " sslConnMax " + self.sslConnMax)
                
            if int(i) >= int(self.sslConnMax) :
                isHighValue=True
                self.print_debug("isHighValue=True sslConnMax " + self.sslConnMax + " i " +  str(i) )
            else:
                self.print_debug("else")
            sum+=i
        
        if isHighValue :
            self.highTpsInProbeTime(timestamp, probeList, mikrosecond)

        if  self.printHeader :
            print "%25s %13s %13s [... %s ... ]" % ("date", "timestamp", "sumOfConn", str(mikrosecond) + " microsecond periods") 
            self.printHeader = False

        secondAux=str(probeCount)                
        print "%25s %13s %13s " % ( dateAux.ctime() , str(timestamp), " sum:" + str(sum)) ,

        tmp=0 
        while tmp<probeCount:
            print "%4d" % ( probeList[tmp] ) ,
            tmp+=1
        print "\n",

    def calculateNrOfConnInOneSecond(self, _mikrosecond):
        mikrosecond = int(_mikrosecond)
        probeCount=1000000/mikrosecond
        probeList = [0]*probeCount
        #self.print_debug(json.dumps(probeList))
        timestamp = None

        self.print_debug("calculate start")
        
        self.init()
         
        timestamp=self.timeList[0][0]
        for i in self.timeList:
            if i[0] > timestamp : 
                self.showRow(timestamp,probeList,mikrosecond)
                probeList = [0]*probeCount
                timestamp=i[0]
            self.print_debug("timestamp " + str(i[0]) + " mikrosecond " + str(i[1]) + " mikrosecond " + str(mikrosecond) )
            #self.print_debug(str(i[1]%mikrosecond) )
            if i[1] >= 1000000 : #a bug someware, it should be another second but is not in the tcpdump output
                probeList[ 999999/mikrosecond ] += 1
            else:
                probeList[ i[1]/mikrosecond ] += 1

        self.showRow(timestamp,probeList, mikrosecond)
        
        self.FH.close()

        return 0

    def extractTime(self, line):
        s, us=re.match("(\d+)\.(\d+)", line).groups()
        self.print_debug("extractTime: " + s + "." + us)

        return long(s), long(us)

    def main(self):

        self.print_debug("main start")
        fileName=sys.argv[1]
        timeProbe=sys.argv[2]
        self.sslConnMax=sys.argv[3]
        #self.sslConnHighFile=sys.argv[4]

        tcpdump=commands.getoutput("tcpdump -tt -nr " + fileName)
        
        self.tcpdumpList=tcpdump.split('\n')
        
        nr=0
        for l in self.tcpdumpList:
            #print "data: " + l
            if re.match("^\d+\.\d+", l):
                second, microsecond = self.extractTime(l)
                self.timeList.append([second, microsecond, nr])
            else:
                print "skeeping the line: " + l
            nr=nr+1
                
        self.print_debug( json.dumps(self.timeList) )

        return self.calculateNrOfConnInOneSecond(timeProbe) #10000

if __name__ == "__main__":
    ssl=SslAnalyze()
    sys.exit(ssl.main())
