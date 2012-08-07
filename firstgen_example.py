import httplib2
httplib2.debuglevel = 1
from cloudservers import CloudServers
u='hugoalmeidauk'
k='391c77192480cbb9969d0514b3daebe1'
cs=CloudServers(u,k)
cs.flavors.list()
