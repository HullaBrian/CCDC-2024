import socket as s
import ipaddress as ip
import os

# This program is just an easy wrapper for a tcpdump command.
# The issued command will write out suspicious network traffic into
# a specified log file.

hostaddress = s.gethostbyname(s.gethostname())
hostIP = ip.ip_address(unicode(hostaddress, "utf-8"))
subnet = int(hostIP) & int(ip.ip_address(u'255.255.255.0'))
subnet_str = str(ip.ip_address(subnet))+"/24"

safe_ports = [53, 20, 21, 80, 443, 25, 22]

port_str = " and not port ".join(list(map(str, safe_ports)))

output_file = "suspicious.txt"

print("sudo tcpdump -ni any 'tcp and (tcp-fin|tcp-syn)!=0 and dst net "+subnet_str+" and src net "+str(ip.ip_address(subnet))+"/8 and not src net "+subnet_str+" and not port "+port_str+" | cut -d ' ' -f 1,3-5 > suspicious.txt &")

def findRange(filename):
	ip_min = int(ip.ip_address(u'255.255.255.255'))
	ip_max = int(ip.ip_address(u'0.0.0.0'))

	f = open(filename, "r")
	entries = f.readlines()
	f.close()
	for entry in entries:
		ip_split = entry.split(" ")[1].split(".")
		ip_str = ".".join(ip_split[:-1])
		ip_int = int(ip.ip_address(unicode(ip_str, "utf-8")))
		if ip_int < ip_min:
			ip_min = ip_int
		if ip_in > ip_max:
			ip_max = ip_int

	return(str(ip.ip_address(ip_min))+" - "+str(ip.ip_address(ip_max)))

