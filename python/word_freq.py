#!/usr/bin/env python3
__author__ = 'Austin Matthews'

'''
Display the frequency of word lengths that appear in a file as the argument.
'''

import sys

def word_length():
    return len(word)

infile = open(sys.argv[1],'a')
infile.close()

infile = open(sys.argv[1], 'r')
readin = infile.read()

for punc in "!@#$%^&*()_+-={}|:\"<>?[]\\;\',./":
    readin = readin.replace(punc, "")
    readin = readin.replace("\n", " ")
    readin = readin.replace("  ", " ")

words = readin.split(" ")

freq = {}
for word in words:
    freq[len(word)] = freq.get(len(word), 0)+1

print("Length Count")
lineout = ""
for word_length in sorted(freq.keys()):
    if word_length == 0:
        continue
    else:
        print("{0:>7} {1:>7}".format(word_length,freq[word_length]))

"""Start histogram graph"""
print("")
i = 400
j = 1
row = ""
while i > 0:
    while j < 16:
        if freq[j] >= i:
            row += "***"
        else:
            row += "   "
        j += 1

    if (i % 100) == 0:
        print("  " + str(i) + " -|{0}".format(row))
    else:
        print("       |{0}".format(row))
    i -= 20
    j = 1
    row = ""

print("    0 -+-+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+-")
print("       | 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16")

infile.close()