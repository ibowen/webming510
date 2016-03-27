#!/usr/bin/env python

from __future__ import print_function
from alchemyapi import AlchemyAPI

import StringIO
import re
import csv
alchemyapi = AlchemyAPI()

# total 318 pages
for num in range(1, 318+1):
	# concatenate url from 1st to the 318th page
	test_url = 'http://zipatlas.com/us/zip-code-comparison/unemployment-rate.'
	if num > 1:
		test_url = test_url + str(num) + '.'
	test_url = test_url + 'htm'
	print('Checking text . . . ' + str(num))
	# use alchemyapi to extract the text in the webpage
	response = alchemyapi.text('url', test_url)
	#assert(response['status'] == 'OK')
	print('Text tests complete!' + str(num))
	# decorate the response text into the file type
	text = StringIO.StringIO(response.get('text'))
	# iterate each line of text to remove characters
	pattern = re.compile(r'[A-Za-z]{1,}')
	with open('unemployment.txt', 'a') as datafile:
                for line in iter(text):
			newline = pattern.sub('', line)
			datafile.write(newline)	

#	with open('eggs.csv', 'a') as csvfile:
#    		spamwriter = csv.writer(csvfile, delimiter=' ', quoting=csv.QUOTE_NONE, escapechar=' ')
#		for line in iter(text):
#			newline = pattern.sub('', line)
#			#print(newline)
#    			spamwriter.writerow(newline)
