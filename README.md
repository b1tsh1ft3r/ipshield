# IPShield

This is a quick and dirty bash script that relies on ipset and iptables to create a blacklist of known malicious IPs and block them
in iptables with a single rule to drop any matches in the black list at the top of the INPUT chain.

# Instructions

This script was quickly developed on ubuntu server 22.04 and is hard coded in many places to be in /opt/ipshield/.
Place this script there and make it executable (chmod +x ipshield.sh).

Create an ipset blacklist for all of the rules to be continuously loaded into.

ipset create blacklist hash:ip maxelem 131072

Create a firewall rule with iptables that looks like so. this should be in your INPUT chain at the very top

iptables -A INPUT -m set --match-set blacklist src -j DROP

Finally cron the script to run once every hour.

#Update blocklists every hour and block with iptables
0 */1 * * * /bin/bash /opt/ipshield/ipshield.sh > /dev/null

This will create a rolling log of the updates happening in /var/log/ipshield.log when the script is triggered and it 
will add a rules to the ipset list and then if traffic coming in through the INPUT chain on iptables matches any one of
the IPs in the blacklist in ipset, it will drop the traffic!

Enjoy!

# References

* https://www.ipdeny.com
* https://www.opendbl.net
