#!/bin/bash

PFP=etc/ssh/sshd_config
grep -q '^KerberosAuthentication yes' $PFP || sed -i s/.*KerberosAuthentication.*/'KerberosAuthentication yes'/ $PFP
grep -q '^KerberosOrLocalPasswd yes' $PFP || sed -i s/.*KerberosOrLocalPasswd.*/'KerberosOrLocalPasswd yes'/ $PFP
grep -q '^KerberosTicketCleanup yes' $PFP || sed -i s/.*KerberosTicketCleanup.*/'KerberosTicketCleanup yes'/ $PFP
grep -q '^UsePAM yes' $PFP || sed -i s/.*UsePAM.*/'UsePAM yes'/ $PFP

exit 0

