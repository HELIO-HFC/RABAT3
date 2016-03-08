#! /usr/bin/env python

def setup_logging(filename = None, quiet = False, verbose = False, debug = False):

    
    """Method to setup a logging instance"""

	import logging
    
	if debug:
		logging.basicConfig(level = logging.DEBUG, format='%(levelname)-8s: %(message)s')
	elif verbose:
		logging.basicConfig(level = logging.INFO, format='%(levelname)-8s: %(message)s')
	else:
		logging.basicConfig(level = logging.CRITICAL, format='%(levelname)-8s: %(message)s')
	
	if quiet:
		logging.root.handlers[0].setLevel(logging.CRITICAL + 10)
	elif verbose:
		logging.root.handlers[0].setLevel(logging.INFO)
	else:
		logging.root.handlers[0].setLevel(logging.CRITICAL)
	
	if filename:
		import logging.handlers
		fh = logging.FileHandler(filename, delay=True)
		fh.setFormatter(logging.Formatter('%(asctime)s %(name)-12s %(levelname)-8s %(funcName)-12s %(message)s', 
                                          datefmt='%Y-%m-%d %H:%M:%S'))
		if debug:
			fh.setLevel(logging.DEBUG)
		else:
			fh.setLevel(logging.INFO)
		
		logging.root.addHandler(fh)

