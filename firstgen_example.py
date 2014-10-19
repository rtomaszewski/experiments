import httplib2
httplib2.debuglevel = 1
from cloudservers import CloudServers
u='hugo-username'
k='key'
cs=CloudServers(u,k)
cs.flavors.list()
