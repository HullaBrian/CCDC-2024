from graphviz import *
from ipaddress import *
import os
import sys
import ipaddress as ip
import xml.etree.ElementTree as ET

### PARSING DEFINTIONS ###

class NetworkAddress:
    def __init__(self, addr_str, subnet, gateway, addr_type):
        # Here we use ipaddress' interface object,
        # as it contains both the address and netmask
        interface_str = addr_str + "/" + subnet
        if addr_type == "ipv4":
            self.interface = ip.IPv4Interface(interface_str)
        else:
            self.interface = ip.IPv6Interface(interface_str)
        self.gateway = ip.ip_address(gateway)

    def __repr__(self):
        return str(self)

    def __str__(self):
        return self.interface.with_prefixlen

class NetworkService:
    def __init__(self, service_xml_root=None):
        self.initDefault()
        if service_xml_root != None:
            self.initXml(service_xml_root)

    def initDefault(self):
        self.proto = ""
        self.port = 0
        self.is_open = False
        self.service_name = ""
        self.product = ""
        self.version = ""
        self.description = ""

    # service_root is the port object in the nmap XML
    def initXml(self, service_root):
        self.proto = service_root.attrib.get('protocol', "")
        self.port = int(service_root.attrib.get('portid', "0"))
        state = service_root.find('state')
        if state != None:
            self.is_open = state.attrib.get('state', "closed") == "open"

        service = service_root.find('service')
        if service != None:
            self.service_name = service.attrib.get('name', "None")
            self.product = service.attrib.get('name', "None")
            self.version = service.attrib.get('version', "None")

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return "Service: " + "{" "Protocol: " + self.proto + ", " + "Port: " + str(self.port) + ", " + \
            "Is Open: " + str(self.is_open) + ", " + "Name: " + self.service_name + ", " + \
                "Product: " + self.product + ", " + "Version: " + self.version + "}"

class NetworkElement:
    def initDefault(self):
        self.is_up = False
        # Each network element is uniquely determined by
        # it's IP address; if a host has two addresses,
        # we treat them as separate.

        self.network_config = None
        self.os = ""
        self.services = []
        self.hostnames = []
        self.description = ""
        self.network = ""

    # host_root corresponds to the host XML element
    def initXml(self, host_root):
        address = host_root.find('address')
        # TODO: Consider failure case
        addr_str = address.attrib.get('addr', "")
        addrtype = address.attrib.get('addrtype', "")
        # TODO: Fix gateway
        self.network_config = NetworkAddress(addr_str, u"255.255.255.0", u"192.168.1.1", addrtype)
        status = host_root.find('status')
        self.status = status.attrib.get('state', "")
        # TODO: Verify
        self.hostnames = [hn.attrib.get('name', "") for hn in host_root.find('hostnames')]
        if self.hostnames == []:
            self.hostnames = [""]

        os_entry = host_root.find('os').find('osmatch')
        if os_entry != None:
            self.os = os_entry.get('name', "")


        for service in host_root.find('ports').findall('port'):
            new_service = NetworkService(service)
            self.services.append(new_service)

    def __init__(self, host_root=None):
        self.initDefault()
        if host_root != None:
            self.initXml(host_root)

    def getServiceByPort(self, port_num, proto):
        # Should only be one (port, service) per network element, but
        # we return a list for consistency
        service_list = []
        for service in self.services:
            if service.port == port_num and service.proto == proto:
                service_list.append(service)
        return service_list

    def getServiceByName(self, service_name):
        service_list = []
        for service in self.services:
            if service.serviceName == service_name:
                service_list.append(service)
        return service_list

    # Providing a list of service_names filters the results to only include
    # open ports with the corresponding service
    def getAllOpenServices(self, service_names=None):
        service_list = []
        for service in self.services:
            if service.is_open:
                if service_names == None or service.name in service_names:
                    service_list.append(service)
        return service_list

    # Returns stringified version of IP, stripped of subnet specification
    def getAddress(self):
        return str(self.network_config.interface)[:-3]

    # Returns ipv4 object of subnet
    def getSubnet(self):
        return self.network_config.interface.network

    # TODO: Unimplemented
    def isGateway(self):
        return False

    def makeEntry(self):
        service_str = ""
        for service in self.getAllOpenServices(None):
            service_str += str(service.port) + ": " + service.service_name + "\n"
        
        return "\n".join([self.hostnames[0], self.getAddress(), self.os, service_str])


# Exported function
def parse_file(filename):
    tree = ET.parse(filename)
    root = tree.getroot()
    elements = []
    for host in root.findall('host'):
        network_element = NetworkElement(host)
        elements.append(network_element)
    return elements

### DIAGRAM DEFINITIONS ###

# This class contains both an unordered list of NetworkElements
# and a dictionary that maps subnets to list of NetworkElements
# on that subnet.
class Network():
    def __init__(self, netElements):
        self.boxes = netElements
        self.subnetDict = {}

    def getSubnets(self):
        s = []
        for box in self.boxes:
            s.append(str(box.getSubnet()))
        subnets = list(frozenset(s))

        return subnets

    def groupBySubnet(self):
        subnets = self.getSubnets()

        for subnet in subnets:
            boxes_in_subnet = []
            for box in self.boxes:
                if str(box.getSubnet()) == subnet:
                    boxes_in_subnet.append(box)
            self.subnetDict[subnet] = boxes_in_subnet

        return self.subnetDict

# The graphNetwork function of this class takes in a dictionary
# from groupBySubnet and displays an associated DOT graph.
class NetworkGraph(Graph):
    def __init__(self, netDict):
        Graph.__init__(self)
        self.networkDict = netDict

    def graphNetwork(self, output_name="graph"):
        self.attr(splines = 'ortho')
        for subnet in self.networkDict:
            self.attr('node', shape='ellipse')
            self.node(subnet, 'Subnet: '+subnet)
            self.attr('node', shape='box')

            i = 0
            for box in self.networkDict[subnet]:
                self.node(subnet+"_"+str(i), box.makeEntry())
                self.edge(subnet, subnet+"_"+str(i))
                i+=1

        self.render(output_name, view=True)


# Main only for testing
if __name__ == '__main__':
    filename = sys.argv[1]
    output_name = sys.argv[2]
    elements = parse_file(filename)
    net = Network(elements)
    net.groupBySubnet()
    graph = NetworkGraph(net.subnetDict)
    graph.graphNetwork(output_name)

