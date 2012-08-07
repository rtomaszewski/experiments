import httplib2
httplib2.debuglevel = 1

OS_USERNAME="ukcloudnova"
OS_PASSWORD="f8d32c75eafaa46d05c4de2919489e67"
OS_AUTH_URL="https://identity.api.rackspacecloud.com/v2.0/"

from novaclient.v1_1 import client
nt=client.Client(OS_USERNAME,OS_PASSWORD,'',OS_AUTH_URL)
nt.flavors.list()

