from TOSSIM import *
from array import *
from RadioCountMsg import *
from PathMsg import *
from RoutMsg import *
import sys
import random
import Queue

baseStation = 0

class Node(object):
	def __init__(self,idNum):
		self.nextNodes = []
		self.pathLength = float('inf')
		self.idNum=idNum

t = Tossim([])
r= t.radio()

listNodes = []
sys.stdout = open('out_test.txt','w')

#read topology once to get number of nodes
f = open("topo.txt", "r")
for line in f:
	s = line.split()
	if s:
		valOne = int(s[0])
		valTwo = int(s[1])
		r.add(int(s[0]), int(s[1]), float(s[2]))
		if valOne not in listNodes:
			listNodes.append(int(s[0]))
		if valTwo not in listNodes:
			listNodes.append(int(s[1]))

numNodes = len(listNodes)
listNodes = []
graph = []
for i in range(numNodes):
	graph.append(Node(-1))
allPaths = [0 for x in range(numNodes)]

#read topology again to construct graph list needed for breadth first search
f = open("topo.txt", "r")
for line in f:
	s = line.split()
	if s:
		valOne = int(s[0])
		valTwo = int(s[1])
		if valOne not in listNodes:
			graph[valOne] = Node(valOne)
			listNodes.append(int(s[0]))
		if valTwo not in listNodes:
			graph[valTwo] = Node(valTwo)
			listNodes.append(int(s[1]))

		graph[valOne].nextNodes.append(valTwo) #add connection from s[0] to s[1] in graph


noise = open("meyer-heavy.txt", "r")
for line in noise:
	str1 = line.strip()
	if str1:
		val = -100
		for i in range(0, numNodes):
			t.getNode(i).addNoiseTraceReading(val)

for i in range(0, numNodes):
	 t.getNode(i).createNoiseModel()

#Find shortest path information
graph[baseStation].pathLength = 0 #path length to same node is 0
que = Queue.Queue()
que.put(graph[baseStation])

while que.qsize() > 0:
	n = que.get()
	curLength = n.pathLength
	connectedNodes = list(n.nextNodes) #gets all connected node indexes
	while len(connectedNodes) != 0:
		curConnNode = graph[connectedNodes.pop()]
		if curConnNode.pathLength == float('inf'):
			curConnNode.pathLength = curLength + 1
			allPaths[curConnNode.idNum] = n.idNum #tells last connected node
			que.put(curConnNode)

allPaths[baseStation] = -1

t.addChannel('RadioCountToLedsC',sys.stdout)
for i in range(numNodes):
	t.getNode(i).bootAtTime(10)

#Declares routing protocol for each node
#1 = AODV
#2 = CTP
for i in range(numNodes):
	msg = RoutMsg()
	msg.set_routing(random.randint(1, 2))
	msg.set_placeholder(0)
	pkt = t.newPacket()
	pkt.setType(msg.get_amType())
	pkt.setData(msg.data)
	pkt.setDestination(i)
	pkt.deliver(i, 11)



#send route info to nodes
for i in range(numNodes):
	msg = PathMsg()
	msg.set_path(allPaths[i]) #tells where to send packets to next
	p = t.newPacket()
	p.setLength(4)
	p.setType(msg.get_amType())
	p.setData(msg.data)
	p.setSource(baseStation)
	p.setDestination(i)
	#pdb.set_trace()
	p.deliver(i, t.time() + 80)
	#print "tried to send"

#send sensor readings to nodes
for j in range(10):
	radioobjs = list()
	for i in range(numNodes):
		radioobjs.append(RadioCountMsg())
		radioobjs[i].set_temp(random.random() *19 + 64)
		radioobjs[i].set_hum(random.random() * 28 + 55)
		radioobjs[i].set_wind(random.random() * 20)
		radioobjs[i].set_num(1)
		pkt = t.newPacket()
		pkt.setType(radioobjs[i].get_amType())
		pkt.setData(radioobjs[i].data)
		if i != baseStation:
			pkt.setDestination(i)
			pkt.deliver(i, t.time() + 200)

for i in range(3000):
	t.runNextEvent()
