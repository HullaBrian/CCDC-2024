#!/bin/python3
# SPDX-License-Identifier: GPL-3.0-only

# Copyright (c) Cody Ho <codyho@stanford.edu>

# Script to *enumerate* all hosts and identify if they're Windows/Unix.
# It does *not* attempt to discover os version, or distro version

import argparse
import subprocess
import threading
import xml.etree.ElementTree as ET

# https://stackoverflow.com/a/65447493 by Shail-Shouryya
class Thread_With_Result(threading.Thread) :
    def __init__(self, group=None, target=None, name=None, args=(), kwargs=None, *, daemon=None) :
        self.result = None
        if kwargs is None : kwargs = {}

        def function() :
            self.result = target(*args, **kwargs)

        super().__init__(group=group, target=function, name=name, daemon=daemon)

# Params: a subnet in the form x.x.x.0/24
# Returns: writes a file to disk with the name nmap-x.x.x.0.xml
def map_network(subnet):
    file_to_write = f"nmap-{subnet[:len(subnet)-3]}.xml"
    nmap = subprocess.run(
        args=[
            "nmap",
            "-p",
            "22,135,445,3389,5985,5986",
            "-O",
            "-sV",
            "-T4",
            "-oX",
            file_to_write,
            subnet
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return file_to_write

# Params: the filename of the xml file
# Return: a map: {
#   'windows': (ip, hostname, guess, confidence, ports),
#   'linux': (ip, hostname, guess, confidence, ports),
#   'bsd': (ip, hostname, guess, confidence, ports),
#   'unknown': (ip, hostname, guess, confidence, ports)
# }
def parse_xml(xml_file):
    host_map = { 'windows': [], 'linux': [], 'unknown': []}
    tree = ET.parse(xml_file)
    root = tree.getroot()
    for host in root.iter("host"):
        try:
            os_type = "unknown" # {windows|linux|unknown}
            open_ports = []

            # retrieve IP, why is this so complicated
            for address in host.iter("address"):
                if address.attrib["addrtype"] == "ipv4":
                    ip = address.attrib["addr"]
                    break

            # retrieve hostname
            if hostnames := host.find("hostnames"):
                hostname = hostnames.find("hostname").attrib["name"]
            else:
                hostname = "unknown_hostname"

            # retrieve open ports, ignore closed and filtered ports
            for port_node in host.find("ports"):
                state = port_node.find("state").attrib["state"]
                if state == "open":
                    port_num = port_node.attrib["portid"]
                    open_ports.append(port_num)
                    if port_num == "22":
                        ssh_version = port_node.find("service").attrib["version"].lower()

            # if every port is closed just assume the host is down
            if not len(open_ports):
                continue

            # first, we use our heuristics to guess the os type based off open ports
            if "3389" in open_ports or "5985" in open_ports or ("135" in open_ports and "445" in open_ports):
                os_type = "windows"
            elif "22" in open_ports:
                if "bsd" in ssh_version:
                    os_type = "unknown"
                else:
                    os_type = "linux"

            # if there were no matches, trust the heuristic (this usually isn't an
            # issue since it's usually windows that causes issues, and the heuristic
            # is pretty good at detecting windows
            os_node = host.find("os").find("osmatch")
            if not os_node:
                host_map[os_type].append((ip, hostname, "None", "0", []))
                continue

            nmap_confidence = os_node.attrib["accuracy"]
            guess = os_node.find("osclass").attrib["osfamily"]

            # second, if nmap is over 90% confident in its first guess, and it's not
            # obviously wrong, just go with that
            print(f"Guess for {ip} is {guess}")
            if int(nmap_confidence) >= 90:
                if guess == "Linux" and "22" in open_ports:
                    os_type = "linux"
                elif guess == "Windows" and ("3389" in open_ports or "445" in open_ports):
                    os_type = "windows"
                # sometimes windows is detected as an old freebsd version since
                # Microsoft stole FreeBSD's network stack
                elif guess == "FreeBSD" and os_node.find("osclass").attrib["osgen"][0] == "6":
                    os_type = "windows"
                # if nmap is over 90% confident our heuristic is incorrect, that's bad
                else:
                    os_type = "unknown"
            else:
                print("Rejecting guess: not confident enough")

            host_map[os_type].append((ip, hostname, guess, nmap_confidence, ','.join(open_ports)))
        except Exception as e:
            print(f"FAILED TO PARSE HOST {host}")
    return host_map

# Params: the map generated by parse_xml() and an output file name
# Return: writes an ansible host list to OUTPUT_FILE
def write_host_file(host_map, output_file):
    def append_to_file(f, entry):
        ip, hostname, guess, confidence, ports= entry
        f.write(f"{ip}\tports={ports}\t#{hostname}\t{guess} {confidence}%\n")

    with open(output_file, "a+") as f:
        f.write("# Unknown or not linux/windows\n")
        for entry in host_map["unknown"]:
            append_to_file(f, entry)
        f.write("\n[linux]\n")
        for entry in host_map["linux"]:
            append_to_file(f, entry)
        f.write("\n[windows]\n")
        for entry in host_map["windows"]:
            append_to_file(f, entry)

# creates a host_map for a subnet
def map_one_net(subnet):
    xml_file = map_network(subnet)
    return parse_xml(xml_file)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output', type=str, required=True, help="Output file name")
    parser.add_argument('-s', '--subnets', type=str, required=True, help="List of subnets to map, seperated by commas")
    args = parser.parse_args()

    if args.output is None:
        print("No output file specified, defaulting to \"preliminary_hosts\"")
        args.output = "preliminary_hosts"

    # internal datastructures
    host_maps = []
    threads = []
    complete_map = {}

    # spawn a thread for each subnet
    # this is sort of stupid since we're using subprocess anyways, but whatever
    for subnet in args.subnets.split(","):
        thread = Thread_With_Result(target=map_one_net, args=(subnet,))
        threads.append(thread)
        thread.start()

    # wait for all the nmap scans to complete
    for thread in threads:
        thread.join()
        host_maps.append(thread.result)

    # merge the maps
    for host_map in host_maps:
        for key, value in host_map.items():
            if key in complete_map:
                complete_map[key].extend(value)
            else:
                complete_map[key] = value

    # write the hosts file
    write_host_file(complete_map, args.output)
    print(f"Done, result saved to {args.output}")
