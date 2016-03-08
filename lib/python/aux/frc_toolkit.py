#! /usr/bin/env python

import logging, csv
import urllib2, os
import time

# Method to check in the input history file if 
# data files have been already processed or not
def check_history(history_file,itemList,
		  log=None):

	if not (os.path.isfile(history_file)):
		if (log): log.warning("%s does not exist!",history_file)
		return []

	# Read the history file
	fr = open(history_file,'r')
	fileList = fr.read().split("\n")
	fr.close()

	# Found processed and unprocessed data files
	processed = [] ; unprocessed = []
	for current_item in itemList:
		if (current_item in fileList):
			processed.append(current_item)
			if (log): log.info("%s already processed.",current_item)
		else:
			unprocessed.append(current_item)
			if (log): log.info("%s not processed.",current_item)

	return processed, unprocessed

# Method to parse the input configuration file
def parse_configfile(configfile):
	
	args = dict()
	try:
		with open(configfile) as f:
			for line in f:
				param = line.strip()
				if param and param[0] != '#':
					params = param.split('=', 1)
					if len(params) > 1:
						args[params[0].strip().upper()]=params[1].strip()
					else:
						args[params[0].strip().upper()]=None
	except IOError, why:
		raise Exception("Error parsing configuration file " + str(configfile) + ": " + str(why))
	
	return args
		
# Method to ... write csv file
def write_csv(content,output_file,
			  delimiter=';',quotechar='"',
			  fieldnames=None):
      
	islist = isinstance(content,list)
	if not (islist):
		content = [content]

	if (fieldnames is None): fieldnames = content[0].keys()

	header={}
	for name in fieldnames: header[name] = name

	try:
		writer = csv.DictWriter(open(output_file,"wb"),fieldnames,
					delimiter=delimiter,quotechar=quotechar,
					quoting=csv.QUOTE_MINIMAL,
					extrasaction='ignore')
		writer.writerow(header)
		for row in content: 
			writer.writerow(row)
	except ValueError:
		return False
	else:
		return True


# Method to download data file
def download_file(url,
		 		  data_directory=".",
		  		  filename="",
		  		  timeout=180):
	
	
	target = "" ; tries=3
	for i in range(tries):
		try:
			connect = urllib2.urlopen(url,None,timeout)
		except urllib2.URLError,e:
			err_msg = "Can not reach %s: %s [%s]" % (url,e,tries-i)
			if 'log' in globals():
				log.warning(err_msg)
			else:
				print err_msg
			time.sleep(3)
			continue
		else:
			if not (filename):
				if (connect.info().has_key('Content-Disposition')):
					filename = connect.info()['Content-Disposition'].split('filename=')[1]
					if (filename.startswith("'")) or (filename.startswith("\"")):
						filename=filename[1:-1]
				else:
					filename=os.path.basename(url)
			target=os.path.join(data_directory,filename)
			if not (os.path.isfile(target)):
				fw = open(target,'wb')
				fw.write(connect.read())
				fw.close()
			else:
				msg = "%s already exists" % (target)
				if 'log' in globals():
					log.info(msg)
				else:
					print msg
			break
	return target

# Method used in Python 2.6 to compute datetime.total_seconds() module operation.
def total_sec(td):
	return (td.microseconds + (td.seconds + td.days * 24 * 3600) * 10**6) / 10**6


# Method to convert a fits format file to a png format file 
# using the convert command of ImageMagick
def fits2png(fitsfile,output_filename,
	         colorspace=None,colorize=None,
	         brightness=None,normalize=None,
	         fill=None,tint=None,
	         VERBOSE=False):

	if not (os.path.isfile(fitsfile)):
		return False
	
	cmd = "convert "+fitsfile
	if (normalize): cmd = cmd + " -normalize"
	if (colorspace): cmd = cmd + " -colorspace "+colorspace
	if (colorize): cmd = cmd + " -colorize "+colorize
	if (brightness): cmd = cmd + " -brightness-contrast "+brightness
	if (fill): cmd = cmd + " -fill "+fill
	if (tint): cmd = cmd + " -tint "+tint
        cmd = cmd+" "+output_filename
	
	if (VERBOSE): print cmd
	cv_process = subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
	if (cv_process.wait() != 0):
		if (VERBOSE):
			print "Conversion has failed!" 
			output, errors = cv_process.communicate()
			print output
			print errors
		return False
	else:
		return True


# Class to use ordered dict (which is not implemented in Python 2.6)
class ordered_dict(dict):
    def __init__(self, *args, **kwargs):
        dict.__init__(self, *args, **kwargs)
        self._order = self.keys()

    def __setitem__(self, key, value):
        dict.__setitem__(self, key, value)
        if key in self._order:
            self._order.remove(key)
        self._order.append(key)

    def __delitem__(self, key):
        dict.__delitem__(self, key)
        self._order.remove(key)

    def order(self):
        return self._order[:]

    def ordered_items(self):
        return [(key,self[key]) for key in self._order]	
