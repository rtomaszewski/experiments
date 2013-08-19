import os
import sys
import json

import pyrax

creds_file = os.path.expanduser("~/rackspace_cloud_credentials")
pyrax.settings.set('identity_type', 'rackspace')
pyrax.set_credential_file(creds_file, "LON")

cs = pyrax.cloudservers
dns = pyrax.cloud_dns

# in this example we will add a PTR to a first cloud server
# feel free to change it 
l=cs.servers.list()
server=l[0]

rec = {'data': '162.13.2.xxx', 'name': 'yourservername.mydomain.com', 'type': 'PTR'}     

# to add the PTR record
dns.add_ptr_records(server,rec)

# to list PTR record for a server
dns.list_ptr_records(server)

