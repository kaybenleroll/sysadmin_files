#! /usr/bin/env python
#
# extract_replay_log.py 
#
# Copyright(c) 2006 - 2008 Progress Software Corporation (PSC). 
# All rights reserved. Use, reproduction, transfer, publication 
# or disclosure is prohibited except as specifically provided 
# for in your License Agreement with PSC.
#
# $Revision: 114214 $ $Date: 2009-06-29 10:22:24 +0100 (Mon, 29 Jun 2009) $
# 

import getopt, os.path, sys, xml.dom.minidom, binascii, base64, zipfile, cStringIO

def usage():
	print "Usage: extract_replay_log.py [options] <replayLogFile>"
	print
	print "Unpack a replay log so it can be replayed into a correlator."
	print
	print "  -o, --output=dir     Put output in directory dir, default is the current"
	print "                       directory"
	print "  -l, --lang=lang      Set the output language for the resulting script to"
	print "                       lang, default: batch. Choices are: shell, batch"
#	print "                       Also: pysys, apamainternal"
#	print "  -t, --testFramework  Generate python which can be run directly from within Apama internal framework"
#	print "  -p, --profile        Perform profiling around the last send operation"
#	print "  -s, --scenarios      Unpack scenario monitors into the original scenario, blocks and functions"
	print "  -n, --noReplayMode   Disable use of replay mode (required for Apama <"
	print "                       4.1)"
	print "  -v, --verbose        Produce verbose output"
	print "  -h, --help           Display this help message and exit"
	print
	sys.exit();
	

################################################################################
#
# Internal methods and constants
#

REPLAY_ITEM_EVENT = 'EVNT'
REPLAY_ITEM_MONITOR = 'MONI'
REPLAY_ITEM_MONITOR_WITHFILENAME = 'MONF'
REPLAY_ITEM_JMON = 'JMON'
REPLAY_ITEM_DELETE = 'DELE'
REPLAY_ITEM_FORCEDEL = 'FDEL'
REPLAY_ITEM_DELALL = 'DLAL'

REPLAY_ITEM_START_DELETE = 'SDEL'
REPLAY_ITEM_START_FORCEDEL = 'SFDL'
REPLAY_ITEM_START_DELALL = 'SDAL'

# Used internally by this tool - not read from replay log
REPLAY_ITEM_SCENARIO = 'SCENARIO'

def basename(s):
	b=os.path.basename(s)
	bs=b.split('\\')
	if len(bs)>1:
		b=bs[len(bs)-1]
	return b

def createFileName(itemType, filename=None):
	global replayFiles, outputFilePrefix, eventIdx
	eventIdx = eventIdx + 1
	name = outputFilePrefix+"%03d" % (eventIdx)
	suffix=''
	if itemType == REPLAY_ITEM_EVENT:
		name = name+".evt"
		suffix='.evt'
	elif itemType == REPLAY_ITEM_MONITOR:
		name = name+".mon"
		suffix='.mon'
	elif itemType == REPLAY_ITEM_MONITOR_WITHFILENAME:
		name = name+".mon"
		suffix='.mon'
	elif itemType == REPLAY_ITEM_JMON:
		name = name+".jar"
		suffix='.jar'
	else:
		raise Exception("Unknown output file type: %s" % itemType)
	
	if filename:
		name = os.path.dirname(outputFilePrefix)+'/'+basename(filename).replace(suffix, ".%03d%s" % (eventIdx, suffix))
		
	return name

def createReplayOutputFile(itemType, filename=None):
	# Create a new .mon or .evt output replay output file 
	# Return a handle to the new file
	
	name = createFileName(itemType, filename)
	
	replayFiles.append( (itemType, name, False) )

	verboseMessage("Writing output file %s ..." % name)

	return file(name, "wb+")

def closeEventFile(isInject=False):
	global eventFile, prevFile
	if prevFile != None:
		prevFile.close()
		prevFile = None
	if eventFile != None:
		if isInject:
			prevFile=eventFile
			eventFile = None
			return
		# Will need to start a new event file next time we get an event
		eventFile.close() 
		eventFile = None
	
def addReplayOutputName(itemType, name, filename):
	global replayFiles
	replayFiles.append( (itemType, name, False) )
	closeEventFile()
	
def hexToBin(hex):
	return binascii.unhexlify(hex)

def splitPath(path):
	s = os.path.split(path)
	if s[0] == '':
		return [s[1]]
	else:
		x = splitPath(s[0])
		x.append(s[1])
		return x

def getScenarioConfig(dirname, names):
	blockCatalogs = []
	functionCatalogs = []
	for name in names:
		if os.path.splitext(name)[1].lower() == '.sdf':
			scenario = name
			continue
		s = splitPath(name)
		if s[0] == 'blocks':
			if s[1] not in blockCatalogs:
				blockCatalogs.append(s[1])
		elif s[0] == 'functions':
			if s[1] not in functionCatalogs:
				functionCatalogs.append(s[1])
		else:
			raise Exception('Unexpected directory in scenario jar: ' + s[0])
	return (dirname, scenario, blockCatalogs, functionCatalogs)
	
def getJar(content, filename):
	lines = content.splitlines()
	for i in range(len(lines)):
		if lines[i].find('// SCENARIO SOURCE:') == 0:
			break
	if i == len(lines) - 1:
		return None
	b64 = cStringIO.StringIO()
	for j in range(i + 1, len(lines)):
		b64.write(lines[j][3:] + '\n')
	return zipfile.ZipFile(cStringIO.StringIO(base64.b64decode(b64.getvalue())))

def processScenario(type, content, filename):
	jar = getJar(content, filename)
	if jar is None:
		return False
	dir = os.path.splitext(createFileName(REPLAY_ITEM_MONITOR, filename))[0]
	os.mkdir(dir)
	jar.extractall(dir)
	replayFiles.append( (REPLAY_ITEM_SCENARIO, getScenarioConfig(dir, jar.namelist()), False) )
	closeEventFile(True)
	return True

def processMonitor(type, content, filename):
	if scenarios and content.find('package Scenario_') != -1:
		if processScenario(type, content, filename):
			return
	monfile = createReplayOutputFile(REPLAY_ITEM_MONITOR, filename)
	monfile.write(content)
	monfile.close()
	closeEventFile(True)

def processJMon(type, content, filename):
	jmonfile = createReplayOutputFile(REPLAY_ITEM_JMON)
	content = hexToBin(content)
	jmonfile.write(content)
	jmonfile.close()
	closeEventFile()

def processActualEvent(event):
	global eventFile, lastSend, prevFile
	if prevFile:
		if event.startswith('&REPLAY_ID'):
			# workaround for a bug in 4.1.0.0-4.1.0.1: the correlator may write inject
			prevFile.write(event)
			prevFile.write('\n')
			return
		else:
			prevFile.close()
			prevFile = None
	if eventFile == None:
		eventFile = createReplayOutputFile(REPLAY_ITEM_EVENT)
		lastSend = len(replayFiles)-1
	
	eventFile.write(event)
	eventFile.write('\n')
	
def processEvent(type, content, filename):
	global version

	if version == 1:
		event = content
	else:
		event = content.split(' ',1)[1]

	processActualEvent(event)
		
def processEnqueue(type, content, filename):
	# Assume enqueue has been turned into a NOP in the replay correlator, and 
	# just send it in like any other event
	processActualEvent(content)

def processReplayMetaData(type, content, filename):
	global replayMode
	if replayMode:
		# Assume enqueue has been turned into a NOP in the replay correlator, and 
		# just send it in like any other event
		processActualEvent(content)

def processTime(type, content, filename):
	# Assume correlator is externally clocked:
	if type == 'STIM':
		processActualEvent('&SETTIME(%s)' % content)
	else:
		processActualEvent('&TIME(%s)' % content)

def processVersion(type, content, filename):
	global version
	print 'Replay version: %s' % content
	version = int(content)
	if version < 3:
		replayMode = False
	
def processHeader(type, content, filename):
	global javaEnabled, replayMode
	dom = xml.dom.minidom.parseString(content)
	print dom.toxml()
	javaEnabled = dom.getElementsByTagName('javaEnabled')[0].childNodes[0].nodeValue == 'true'
	logMode = 'replayLog'
	try:
		logMode = dom.getElementsByTagName('replayLogMode')[0].childNodes[0].nodeValue
	except:
		pass
	print "Replay log mode assumed to be:", logMode
	if logMode == 'inputLog':
		replayMode= False
		

def processRandomSeed(type, content, filename):
	global seed
	print "RandomSeed:", content
	seed = int(content)

def ignoreMessage(type, content, filename):
	pass
	
def skipSpace(replayLog):
	ws = replayLog.read(1)
	if ws != ' ':
		raise Exception('Unexpected character: ' + ws)
		
def skipNewline(replayLog):
	ws = replayLog.read(1)
	if ws != '\n':
		raise Exception('Unexpected character: ' + ws)

typeDispatch = {
	REPLAY_ITEM_EVENT : processEvent,
	REPLAY_ITEM_MONITOR : processMonitor,
	REPLAY_ITEM_MONITOR_WITHFILENAME : processMonitor,
	REPLAY_ITEM_JMON : processJMon,
	'TIME' : processTime,
	'STIM' : processTime,
	'ENQU' : processEnqueue,
	'RMDT' : processReplayMetaData,
	REPLAY_ITEM_DELETE : addReplayOutputName,
	REPLAY_ITEM_FORCEDEL : addReplayOutputName,
	REPLAY_ITEM_DELALL : addReplayOutputName,
	REPLAY_ITEM_START_DELETE: addReplayOutputName,
	REPLAY_ITEM_START_FORCEDEL: addReplayOutputName,
	REPLAY_ITEM_START_DELALL: addReplayOutputName,
	'VERS': processVersion,
	'HEAD': processHeader,
	'RAND': processRandomSeed,
	'CONN' : ignoreMessage,
	'DISC' : ignoreMessage
}

javaEnabled = True
version = 1

def addWaitingOperation(pendingOperations, type, name):
	n=(type,name)
	if pendingOperations.has_key(n):
		pendingOperations[n]=pendingOperations[n]+1
	else:
		pendingOperations[n]=1

def finishedWaitingOperation(pendingOperations, type, name):
	global version

	if version < 3:
		return
	n=(type,name)
	if pendingOperations.has_key(n):
		pendingOperations[n]=pendingOperations[n]-1
		if pendingOperations[n]==0:
			del pendingOperations[n]
	else:
		raise "Operation without start"


def checkForPendingOperations(replayFiles):
	pendingOperations={}
	newReplayFiles=[]
	for (itemType, fileName, isLastSend) in replayFiles:
		add=True
		if itemType == REPLAY_ITEM_START_DELETE:
			addWaitingOperation(pendingOperations, REPLAY_ITEM_DELETE, fileName)
			add=False
		elif itemType == REPLAY_ITEM_START_FORCEDEL:
			addWaitingOperation(pendingOperations, REPLAY_ITEM_FORCEDEL, fileName)
			add=False
		elif itemType == REPLAY_ITEM_START_DELALL:
			addWaitingOperation(pendingOperations, REPLAY_ITEM_DELALL, "")
			add=False
		elif itemType == REPLAY_ITEM_DELETE:
			finishedWaitingOperation(pendingOperations, REPLAY_ITEM_DELETE, fileName)
		elif itemType == REPLAY_ITEM_FORCEDEL:
			finishedWaitingOperation(pendingOperations, REPLAY_ITEM_FORCEDEL, fileName)
		elif itemType == REPLAY_ITEM_DELALL:
			finishedWaitingOperation(pendingOperations, REPLAY_ITEM_DELALL, "")
		if add:
			newReplayFiles.append((itemType, fileName, isLastSend))
	for n in pendingOperations.keys():
		print "Warning: pending operation %s (%i of)" % (n, pendingOperations[n])
		for i in range(0, pendingOperations[n]):
			newReplayFiles.append((n[0], n[1], False))
	return newReplayFiles
		

################################################################################
#
# extractReplayLog method
#

def extractReplayLog(replayLogFileName, outputFileNamePrefix='./replay_'):
	""" Convert the specified replay log to a series of .evt and .mon files. 
	Returns an array of (itemType, outputFileName) tuples.
	
		replayLogFileName -- input file.
		outputFilePrefix -- directory/filename prefix for output replay files.
	"""
	global eventIdx, eventFile, replayFiles, outputFilePrefix, lastSend, prevFile
	# Initialize globals for this method invocation
	lastSend = -1
	eventIdx = 0
	eventFile = None
	prevFile = None
	replayFiles = []
	outputFilePrefix = outputFileNamePrefix
	
	replayLogDirectory = os.path.dirname(replayLogFileName)
	
	replayLog = open(replayLogFileName, 'rb')
	
	try:
		
		while 1: # Loop through entire input file
			
			# Read in type
			type = replayLog.read(4)
			if len(type) < 4:
				break
			skipSpace(replayLog)
			
			# Read in size of content
			lengths = replayLog.read(8)
			if len(lengths) != 8:
				raise Exception('Early EOF')
			skipSpace(replayLog)

			# Read in content
			length = int(lengths, 16)
			content = replayLog.read(length)
			if len(content) != length:
				raise Exception('Early EOF')

			filename = None
			
			if type in ['MONF']:
				skipSpace(replayLog)
				filenamelengths = replayLog.read(8)
				if len(filenamelengths) != 8:
					raise Exception('Early EOF')
				skipSpace(replayLog)
				filenameLength = int(filenamelengths, 16)
				filename = replayLog.read(filenameLength)
				if len(filename) != filenameLength:
					raise Exception('Early EOF')
			skipNewline(replayLog)
			
			# Process content
			if type == 'NLOG':
				replayLogFileName = os.path.join(replayLogDirectory, os.path.basename(content))
				replayLog.close()
				replayLog = open(replayLogFileName, 'rb')
			else:
				typeDispatch[type](type, content, filename)
		
	finally:
		replayLog.close()
		if eventFile != None:
			eventFile.close()
		if prevFile != None:
			prevFile.close()
	if lastSend >= 0:
		replayFiles[lastSend]=(replayFiles[lastSend][0],replayFiles[lastSend][1],True)
	return replayFiles
	
	
class BaseHandler:
	# Transform the command line output directory into the one that the event files should
	# be written into. Returns what is passed in for most handler types
	def getOutputDirectory(self, outputdir):
		return outputdir

class ShellHandler(BaseHandler):
	def processFiles(self, replayFiles):
		shellScriptFileName = outputFileNamePrefix+'execute.sh'
		shellScriptFile = file(shellScriptFileName, "w")
		shellScriptFile.write('#!/bin/sh\n')
		for (itemType, fileName, isLastSend) in replayFiles:
			if itemType == REPLAY_ITEM_EVENT:
				if profile and isLastSend:
					shellScriptFile.write('engine_management -r "profiling on"\n')
				shellScriptFile.write('engine_send --utf8 "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_MONITOR or itemType == REPLAY_ITEM_MONITOR_WITHFILENAME:
				shellScriptFile.write('engine_inject --utf8 "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_JMON:
				shellScriptFile.write('engine_inject -j "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_DELETE:
				shellScriptFile.write('engine_delete "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_FORCEDEL:
				shellScriptFile.write('engine_delete -F "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_DELALL:
				shellScriptFile.write('engine_delete -a\n')
			else:
				raise Exception("Unexpected item type: %s" % itemType)

		if profile:
			shellScriptFile.write('# Wait for correlator queues to drain, then run engine_management -r "profiling get"\n')
		shellScriptFile.close()
		verboseMessage("Writing shell script %s ..." % shellScriptFileName)

class BatchHandler(BaseHandler):
	def processFiles(self, replayFiles):
		shellScriptFileName = outputFileNamePrefix+'execute.bat'
		shellScriptFile = file(shellScriptFileName, "w")
		for (itemType, fileName, isLastSend) in replayFiles:
			if itemType == REPLAY_ITEM_EVENT:
				if profile and isLastSend:
					shellScriptFile.write('engine_management -r "profiling on"\n')
				shellScriptFile.write('engine_send --utf8 "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_MONITOR or itemType == REPLAY_ITEM_MONITOR_WITHFILENAME:
				shellScriptFile.write('engine_inject --utf8 "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_JMON:
				shellScriptFile.write('engine_inject -j "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_DELETE:
				shellScriptFile.write('engine_delete "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_FORCEDEL:
				shellScriptFile.write('engine_delete -F "%s"\n' % fileName)
			elif itemType == REPLAY_ITEM_DELALL:
				shellScriptFile.write('engine_delete -a\n')
			else:
				raise Exception("Unexpected item type: %s" % itemType)

		if profile:
			shellScriptFile.write('REM Wait for correlator queues to drain, then run engine_management -r "profiling get"\n')
		shellScriptFile.close()
		verboseMessage("Writing BATCH script %s ..." % shellScriptFileName)
	
class PysysHandler(BaseHandler):
	def getOutputDirectory(self, outputdir):
		r = os.system('pysys.py make %s' % outputdir)
		if r != 0:
			raise Exception('Unable to create test with pysys')
		self.testName = outputdir
		return os.path.join(outputdir, 'Input')
		
	def processFiles(self, replayFiles):
			global seed, version, replayMode
			if version>=3 and replayMode:
				argFlag = "'--replayMode'"
			else:
				argFlag = "'-XignoreEnqueue'"
			pythonScriptFileName = os.path.join(self.testName, 'run.py')
			pythonScriptFile = file(pythonScriptFileName, "w")
			pythonScriptFile.write("from pysys.constants import *\n")
			pythonScriptFile.write("from pysys.basetest import BaseTest\n")
			pythonScriptFile.write("from progress.apama.correlator import CorrelatorHelper\n\n")
			pythonScriptFile.write("class PySysTest(BaseTest):\n\n")
			pythonScriptFile.write("\tdef execute(self):\n")
			pythonScriptFile.write("\t\t# create the correlator helper\n")
			pythonScriptFile.write("\t\tcorrelator = CorrelatorHelper(self)\n")
			pythonScriptFile.write("\t\tcorrelator.start(logfile='correlator.log', java=TRUE, Xclock=TRUE, arguments=[%s,'-XsetRandomSeed','%d'])\n\n" % (argFlag, seed))
		
			for (itemType, fileName, isLastSend) in replayFiles:
				if itemType == REPLAY_ITEM_EVENT:
					if profile and isLastSend:
						pythonScriptFile.write('\t\tcorrelator.manage(arguments=["-r", "profiling on"])\n')
					pythonScriptFile.write('\t\tcorrelator.send("%s", utf8=TRUE)\n' % os.path.basename(fileName))
				elif itemType == REPLAY_ITEM_MONITOR or itemType == REPLAY_ITEM_MONITOR_WITHFILENAME:
					pythonScriptFile.write('\t\tcorrelator.injectMonitorscript("%s", utf8=TRUE)\n' % os.path.basename(fileName))
				elif itemType == REPLAY_ITEM_JMON:
					pythonScriptFile.write('\t\tcorrelator.injectJMON("%s", args="-j")\n' % os.path.basename(fileName))
				elif itemType == REPLAY_ITEM_DELETE:
					pythonScriptFile.write('\t\tcorrelator.delete(["%s"])\n' % fileName)
				elif itemType == REPLAY_ITEM_FORCEDEL:
					pythonScriptFile.write('\t\tcorrelator.delete(["%s"], force=TRUE)\n' % fileName)
				elif itemType == REPLAY_ITEM_DELALL:
					pythonScriptFile.write('\t\tcorrelator.delete(all=TRUE)\n')
				else:
					raise Exception("Unexpected item type: %s" % itemType)
					
			pythonScriptFile.write("\t\tcorrelator.flush()\n")
			if profile:
				pythonScriptFile.write('\t\tcorrelator.manage(arguments=["-r", "profiling get"], stdout=os.path.join(self.output, "profile.log"))\n')
			pythonScriptFile.write("\n\tdef validate(self):\n")
			pythonScriptFile.write("\t\tpass\n")
			
			pythonScriptFile.close()
			verboseMessage("Writing pysys run script %s ..." % pythonScriptFileName)
	
class ApamaInternalHandler(BaseHandler):
	def processFiles(self, replayFiles):
		global seed, version, replayMode
		pythonScriptFileName = outputFileNamePrefix+'execute.py'
		pythonScriptFile = file(pythonScriptFileName, "w")
		pythonScriptFile.write('# For use with the Apama test framework.\n#\n#\n\n')

		sourceDir = ""
		if testFramework:
			sourceDir = ", filedir=self.pathOutputFile()"

		if not testFramework:
			javaFlag = str(javaEnabled)
			argFlag='-XignoreEnqueue'
			if version>=3 and replayMode:
				argFlag = "--replayMode"
			pythonScriptFile.write("\t\tself.startCorrelator(Xclock=TRUE, args='%s -XsetRandomSeed %d', abortOnError=TRUE, java=%s)\n\n" % (argFlag, seed, javaFlag))



		for (itemType, fileName, isLastSend) in replayFiles:
			# use base names, so test can be located anywhere on disk
			if not testFramework:
				pythonScriptFile.write('\t\t')
			if itemType == REPLAY_ITEM_EVENT:
				if profile and isLastSend:
					pythonScriptFile.write('self.manage(argList=["-r","profiling on"])\n')
					if not testFramework:
						pythonScriptFile.write('\t\t')
				pythonScriptFile.write('self.send(   "%s", utf8=TRUE%s )\n' % (os.path.basename(fileName), sourceDir))
			elif itemType == REPLAY_ITEM_MONITOR or itemType == REPLAY_ITEM_MONITOR_WITHFILENAME:
				pythonScriptFile.write('self.inject( "%s", utf8=TRUE%s )\n' % (os.path.basename(fileName), sourceDir))
			elif itemType == REPLAY_ITEM_SCENARIO:
				# Not actually fileName in this case:
				scenarioData = fileName
				dirName = os.path.basename(scenarioData[0])
				scenarioName = os.path.splitext(scenarioData[1])[0]
				if testFramework:
					rootDir = 'self.pathOutputFile("' + dirName + '")'
				else:
					rootDir = 'self.pathInputFile("' + dirName + '")'
				args = []
				for b in scenarioData[2]:
					args.append('"-XaddBlockPaths"')
					args.append(rootDir + ' + "/' + 'blocks' + '/' + b + '"')
				for f in scenarioData[3]:
					args.append('"-XaddFunctionPaths"')
					args.append(rootDir + ' + "/' + 'functions' + '/' + f + '"')
				pythonScriptFile.write('self.generateMonitor(sdfname="%s", sdfdir=%s, args=[%s])\n' % (scenarioData[1], rootDir, ','.join(args)))
				if not testFramework:
					pythonScriptFile.write('\t\t')
				pythonScriptFile.write('self.inject( "%s.mon", utf8=TRUE, filedir=self.pathOutputFile())\n' % scenarioName)
			elif itemType == REPLAY_ITEM_JMON:
				pythonScriptFile.write('self.inject( "%s", args="-j"%s)\n' % (os.path.basename(fileName), sourceDir))
			elif itemType == REPLAY_ITEM_DELETE:
				pythonScriptFile.write('self.delete( "%s" )\n' % fileName)
			elif itemType == REPLAY_ITEM_FORCEDEL:
				pythonScriptFile.write('self.delete( "%s", args = "-F" )\n' % fileName)
			elif itemType == REPLAY_ITEM_DELALL:
				pythonScriptFile.write('self.delete( all=1 )\n')
			else:
				raise Exception("Unexpected item type: %s" % itemType)

		pythonScriptFile.write("\n")
		if not testFramework:
			pythonScriptFile.write('\t\t')
		if version>=3 and replayMode:
			pythonScriptFile.write("self.manage(argList=['-r','flushAllQueues'])\n")
		else:
			pythonScriptFile.write("self.waitForCompleteEvent()\n")
		if profile:
			if not testFramework:
				pythonScriptFile.write('\t\t')
			pythonScriptFile.write('self.manage(argList=["-r","profiling get"])\n')
		pythonScriptFile.close()
		verboseMessage("Writing python script %s ..." % pythonScriptFileName)

def verboseMessage(message):
	global verbose
	if verbose:
		print message
	
outputFileNamePrefix = 'replay_'
outputDirectory = '.'
verbose = False
language = 'batch'
testFramework = False
profile = False
replayMode = True
scenarios = False
handlers = {
	'shell': ShellHandler(),
	'batch': BatchHandler(),
	'pysys': PysysHandler(),
	'apamainternal': ApamaInternalHandler(),
}

################################################################################
#
# Entry point
#

def main():

	global outputFileNamePrefix, outputDirectory, verbose, language, testFramework, javaEnabled, profile, replayMode, scenarios

	try:
		opts, args = getopt.getopt(sys.argv[1:], "ho:l:tvpns", ["help", "output=", "verbose", "lang=", "testFramework", "profile", "noReplayMode", "scenarios"])
	except getopt.GetoptError, err:
		print err
		print
		usage()
	for o, a in opts:
		if o in ("-h", "--help"):
			usage()
		if o in ("-o", "--output"):
			outputDirectory = a
		if o in ("-v", "--verbose"):
			verbose = True
		if o in ("-l", "--lang"):
			language = a
		if o in ("-t", "--testFramework"):
			testFramework = True
			pysys=False
		if o in ("-p", "--profile"):
			profile = True
		if o in ("-s", "--scenarios"):
			scenarios = True
		if o in ("-n", "--noReplayMode"):
			replayMode = False
	if len(args) != 1:
		print "Must specify one, and only one, replay log file name"
		print
		usage()
	replayLogFileName = args[0]
	
	handler = handlers[language]
	outputDirectory = handler.getOutputDirectory(outputDirectory)

	if not os.access(outputDirectory, os.F_OK):
		os.makedirs(outputDirectory)
	outputFileNamePrefix = os.path.join(outputDirectory, outputFileNamePrefix)
	
	# Create replay output files
	replayFiles = extractReplayLog(replayLogFileName=replayLogFileName, outputFileNamePrefix=outputFileNamePrefix)
	
	replayFiles = checkForPendingOperations(replayFiles)
	
	handler.processFiles(replayFiles)

	# Done
	verboseMessage("Done.")

if __name__ == "__main__":
	main()
		
