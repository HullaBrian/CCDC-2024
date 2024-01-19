from graphviz import *
from ipaddress import *
import nmap_parser
from nmap_parser import NetworkElement


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

    def graphNetwork(self):
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

        self.render('test_output', view=True)

