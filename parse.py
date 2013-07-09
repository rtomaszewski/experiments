#!/usr/bin/python 
#
## tested on python 2.6.5
#
# author : radoslaw tomaszewski
 
import sys
import re
import inspect
 
 
class ParseTsharkOut:
  no=0
  debugYes=0
     
  ipRe=None
  tcpRe=None
  protRe=None
   
  ipInfo=[]
  tcpInfo=[]
  protInfo=[]
   
  auxStart=0
  tcpAuxStart=0
 
  protAux=1
   
  def __init__(self):
    self.ipRe="Internet Protocol(.*)$"
    self.tcpRe=["Transmission Control Protocol,(.*)$", "    (\[Stream index:.*)$"]
    self.protRe=["Hypertext Transfer Protocol", "    ([^\[ ].*)$", "^$| *(\\\\r|\\\\n)"]
     
  def debug(self, s):
    if self.debugYes : 
      parent=inspect.stack()[1][3]
      #parent=inspect.stack()
      print("debug:[" + str(parent) + "] " +  s.rstrip())
   
  def usage(self):
    print("todo")   
   
  def ipParse(self,s):
    self.debug(s)
 
    tmp=re.match(self.ipRe, s)
#    tmp=re.match("..", s)
    if tmp is None :
       return 0
    else:
       self.ipInfo.append(tmp.group(0))
       return 1
        
  def tcpParse(self,s):
    self.debug(s)
    ret=0
 
    tmp=re.match(self.tcpRe[self.tcpAuxStart], s)
    if tmp is None :
       return 0
    else:
       self.tcpInfo.append(tmp.group(0))
        
       ret=self.tcpAuxStart
       self.tcpAuxStart=(self.tcpAuxStart + 1 ) % 2
        
       return ret
   
  def protParse(self,s):
    self.debug(s)
 
    if ( self.protAux ) :
       if re.match(self.protRe[0], s):
         self.protAux=0
         return 0
          
    else :
       if re.match(self.protRe[2], s):
         self.protAux=1
         self.show()
         return 1
 
       tmp=re.match(self.protRe[1], s)
       if tmp is None :
         return 0
       else:
         self.protInfo.append(tmp.group(0))
         return 0
     
  def parse(self, s):
    funcs=[self.ipParse, self.tcpParse, self.protParse]
    
    if funcs[self.auxStart](s):
      self.auxStart= ( self.auxStart + 1 ) % 3
   
  def show(self):
    self.debug("start")
     
    for i in self.ipInfo:
      print(i)
       
    for i in self.tcpInfo:
      print(i)
 
    for i in self.protInfo:
      print(i)  
       
    print("")
       
    self.ipInfo=[]
    self.tcpInfo=[]
    self.protInfo=[]      
   
  def main(self):
    try:
      if sys.argv[1] == '-d':
        self.debugYes=1
        self.debug("debuging is turn on")
    except (IndexError):
      None
       
    self.debug("main start")
 
    for l in sys.stdin:
      self.parse(l)  
       
    return 0 
       
   
 
if __name__ == "__main__":
        sys.exit(ParseTsharkOut().main())
