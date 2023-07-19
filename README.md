# IPShield

This is a quick and dirty bash script that relies on ipset and iptables to create a blacklist of known malicious IPs and block them
in iptables with a single rule to drop any matches in the black list at the top of the INPUT chain.

# Instructions

This script was quickly developed on ubuntu server 22.04 and is hard coded in many places to be in /opt/ipshield/.
Place this script there and make it executable (chmod +x ipshield.sh) and then cron the script to run once every hour.

#Update blocklists every hour and block with iptables
0 */1 * * * /bin/bash /opt/ipshield/ipshield.sh > /dev/null

This will create a rolling log of the updates happening in /var/log/ipshield.log when the script is triggered and it 
will add a rule to iptables at the top of the INPUT chain which will drop any traffic if it matches one of the ips or
subnets in the black list. 

Enjoy!

# References

* https://www.ipdeny.com
* https://www.opendbl.net
