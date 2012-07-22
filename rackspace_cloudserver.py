
import getopt
import sys
import httplib
from pprint import pprint
from pprint import pformat

DEBUG=1
PROGRAM_NAME="rackspace_cloudserver.py"

##http://docs.rackspace.com/auth/api/v1.1/auth-client-devguide/content/List_Versions-d1e232.html
#endpoints=[ 
#   "https://lon.identity.api.rackspacecloud.com",
#   "https://identity.api.rackspacecloud.com"
#]


#http://docs.rackspace.com/servers/api/v1.0/cs-devguide/content/Authentication-d1e506.html
endpoints=[
           ("lon.auth.api.rackspacecloud.com", "/v1.0")
#           (    "auth.api.rackspacecloud.com", "/v1.0")
]

def log(message):
    print message 

def debug(message, debug=DEBUG):
    if debug==1:
        log("debug[%2d]: " % DEBUG + message)

def usage(message=None):
    if message is not None: 
        print message
    
    print """
    usage: %s [-v] [-h] -u user -k key run | help
      -h  usage help 
      -v - verbose/debug output
      -u 
      -k 
      
      args:
        help - displays info about this program
        run - run this program
       
""" % PROGRAM_NAME 

def autenticate(user, key):
    for (e, index ) in endpoints:
        conn=httplib.HTTPConnection(e)
        
        conn.request("GET", index)
        
        res = conn.getresponse()
        debug(pformat(res))
        #debug("res: " + res.status + " " + r1.reason)
        
        data1 = res.read()
        conn.close()
        
    
    

def main(): 
    debug("main start")
    debug(sys.argv[0])
    
    optlist, args = getopt.getopt(sys.argv[1:], 'vu:k:')
    
    debug("options: " + ', '.join( map(str,optlist) ) ) 
    debug("arguments: " + ", ".join(args ))
    
    user, key = None, None
    
    for o, val in optlist:
        if o == "-v":
            DEBUG = 1
        elif o == "-h":
            usage()
            sys.exit()
        elif o =="-u":
            user=val
        elif o =="-k":
            key=val
        else:
            assert False, "unhandled option"
            
    debug("user: <" + user + "> key: <" + key + ">")
        
    if args[0] == "help":
        usage("displaying help")
        sys.exit()    
    elif args[0] is None: 
        usage("missing argument")
        sys.exit()
    elif args[0] == "run" and user is not None and key is not None:
        autenticate(user, key)
    else:
        usage("recognised argument")
        sys.exit()
    
    

if __name__ == '__main__': 
    main()
        