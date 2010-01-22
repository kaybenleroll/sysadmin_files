import string, sys, os, re

# need to be running python 2.4 or later
version = string.split(string.split(sys.version)[0], ".")
if map(int, version) < [2, 4]:
	print version
	print "Unable to run script (python version needs to be 2.4 or later) ... exiting "
	sys.exit(1)

#expr1 = re.compile('^Monitor:(?P<monitor>.*):.*$', re.M)
expr1 = re.compile('^Monitor:(?P<monitor>.*).*$', re.M)
expr2 = re.compile('^Event:(?P<event>).*$', re.M)
contents = []
monitors = {}
events = {}
totalCPUMonitors = {}
contexts={}

# parse the output from the profile command 
def parseProfile(filename):
	first = True
	
	if not os.path.exists(filename):
		print "Unable to locate specified file ... exiting"		
		sys.exit(1)
	
	f = open(filename, "r")
	for line in f.readlines():
		if first:
			ticks = int(line.strip().split(':')[1])
			first = False
		else:
			l = line.strip().split(',')
			if len(l) == 6:
				#print "Reading " + line.strip()
				contents.append(line.strip().split(','))
				
	contents.sort(lambda x,y: cmp(int(x[5]), int(y[5])), reverse=True)


	for line in contents:
		matchObj= expr1.match(line[2])
		if matchObj: 
			if monitors.has_key(matchObj.group('monitor')):
				monitors[matchObj.group('monitor')].append(line)
				totalCPUMonitors[matchObj.group('monitor')] = totalCPUMonitors[matchObj.group('monitor')] + ( float(line[5])/float(ticks) * 100.0)
			else:
				monitors[matchObj.group('monitor')] = [line]
				totalCPUMonitors[matchObj.group('monitor')] = ( float(line[5])/float(ticks) * 100.0)
				
		matchObj= expr2.match(line[2])
		if matchObj: 
			if events.has_key(matchObj.group('event')):
				events[matchObj.group('event')].append(line)
			else:
				events[matchObj.group('event')] = [line]
		
		contextIdPlusName=line[1]+"(id="+line[0]+")"
		if contexts.has_key(contextIdPlusName):
			contexts[contextIdPlusName] = contexts[contextIdPlusName] + ( float(line[5])/float(ticks) * 100.0)
		else:
			contexts[contextIdPlusName] = ( float(line[5])/float(ticks) * 100.0)
	
	
	print "\nDetailed percentage CPU time (contexts)"
	print "------------------------------------"
	l = []
	for key in contexts.keys(): l.append([contexts[key], key])
	l.sort(lambda x,y: cmp(int(x[0]), int(y[0])), reverse=True)		
	for line in l:
		print "%5.2f %s" % ( line[0], line[1])
	
				
	print "\nTotal percentage CPU time (monitors)"
	print "------------------------------------"
	l = []
	for key in totalCPUMonitors.keys(): l.append([totalCPUMonitors[key], key])
	l.sort(lambda x,y: cmp(int(x[0]), int(y[0])), reverse=True)		
	for line in l:
		print "%5.2f %s" % ( line[0], line[1])
		
	
			
	print "\nDetailed percentage CPU time (monitors)"
	print "---------------------------------------"
	for key in monitors.keys():
		for line in monitors[key]:
			print "%5.2f %s,%s,%s " % ( ( float(line[5])/float(ticks) * 100.0), line[2], line[4], line[5])

	
	print "\nDetailed percentage CPU time (events)"
	print "-------------------------------------"
	l = []
	for key in events.keys():
		for line in events[key]:
			l.append(line)
			
	l.sort(lambda x,y: cmp(int(x[5]), int(y[5])), reverse=True)
	for line in l:
		print "%5.2f %s,%s,%s " % ( ( float(line[5])/float(ticks) * 100.0), line[2], line[4], line[5])
			
	print "\nDetailed percentage CPU time (all)"
	print "----------------------------------"
	for line in contents:
		print "%5.2f %s,%s,%s " % ( ( float(line[5])/float(ticks) * 100.0), line[2], line[4], line[5])
		
# entry point for calling as a command line utility
if __name__ == "__main__":
	if len(sys.argv) < 2:
		print "Usage: profile <filename>"
		sys.exit()
	else:
		parseProfile(sys.argv[1])
		