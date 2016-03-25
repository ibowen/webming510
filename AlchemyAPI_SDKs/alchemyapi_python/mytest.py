#!/usr/bin/env python

from __future__ import print_function
from alchemyapi import AlchemyAPI

import csv
alchemyapi = AlchemyAPI()

# total 318 pages
for num in range(1, 318+1):
	test_url = 'http://zipatlas.com/us/zip-code-comparison/unemployment-rate.'
	if num > 1:
		test_url = test_url + str(num) + '.'
	test_url = test_url + 'htm'
	print('Checking text . . . ' + str(num))
	response = alchemyapi.text('url', test_url)
	#assert(response['status'] == 'OK')
	print('Text tests complete!' + str(num))
	text = response.get('text')
	#print(text)

	with open('unemployment.txt', 'a') as datafile:
    		datafile.write(text)
#print(text)
