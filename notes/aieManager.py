#!/usr/bin/env python

""" GE Search AIE Manager tool """


# import custom modules for '$ pip install -r requirements.txt'
import pexpect
import sys
import time
import re
import getopt
import os


# functions
def get_status(aie):
    """probes the AIE manager to verify the system's health"""
    aie.sendline('status')
    aie.expect('aie>')
    results = aie.before
    cleanDict = {}
    resultArray = results.split('\n')
    for i in resultArray:
        try:
            if i[0].islower():
                for b in re.sub(' +', ' ', i).split('\n'):
                    cleanDict[b.split(' ')[1]] = b.split(' ')[6].rstrip()
        except:
            pass
    return cleanDict, aie


def deploy_project():
    """inserts the proper syntax to deploy a project"""
    aie.sendline('deploy force norestart')
    aie.expect('aie>')
    results = aie.before
    return results, aie


def manage_row(c, a, n):
    """inserts the proper syntax for aie> command on a row"""
    if n == 'adm-te':
        aie.sendline('%s nodeset %s' % (c, a))
    else:
        aie.sendline('%s nodeset %s-%s' % (c, a, n))
    aie.expect('aie>')
    results = aie.before
    return results, aie


def start_aie():
    """starts up the AIE manager"""
    os.chdir('/appl1/libSrch/Attivio/sc_multiv42')
    aie = pexpect.spawn('/appl1/libSrch/Attivio/aie_4.2.0/bin/aie-cli -sc /appl1/libSrch/Attivio/sc_multiv42')
    aie.expect('aie>')
    return aie


def manage_node(aie, c, n):
    """inserts the proper syntax for aie> command on a node"""
    aie.sendline('%s node %s' % (c, n))
    aie.expect('aie>')
    results = aie.before
    return results, aie


def get_help():
    """prints out the command help / usage message"""
    print("[USAGE] aieManager.py -c [status|start|stop] -n [ts|te|node_name|adm-te]\n")
    print("     aieManager.py -c status -n [ts|te] (troubleshoot|te-count)\n")
    print("     aieManager.py -c start -n [node_name|adm-te] (single node|adm + processors)\n")
    print("     aieManager.py -c stop -n [node_name|adm-te] (single node|adm + processors)\n")
    print("[WARNING] replaceconf is for backup process - it will bring the entire cluster row down")
    print("     aieManager.py -c replaceconf -n [1|2] (row number)\n")
    sys.exit(1)


# valid nodes and groups them into rows and index|search
validStatus = ["RUNNING", "STOPPED", "STOPPING", "STARTING", "DIED", "NOT_STARTED"]
validNodes = ["adm", "idxlib1a", "idxlib1b", "idxlib1c", "idxlib1d", "idxlib1e", "idxlib1f", "idxlib2a",
              "idxlib2b", "idxlib2c", "idxlib2d", "idxlib2e", "idxlib2f", "srclib1a", "srclib1b", "srclib1c",
              "srclib1d", "srclib1e", "srclib1f", "srclib1g", "srclib1h", "srclib1i", "srclib1j", "srclib1k",
              "srclib1l", "srclib2a", "srclib2b", "srclib2c", "srclib2d", "srclib2e", "srclib2f", "srclib2g",
              "srclib2h", "srclib2i", "srclib2j", "srclib2k", "srclib2l", "telib1", "telib2", "perfmon",
              "store", "null"]
row1Index = ["idxlib1a", "idxlib1b", "idxlib1c", "idxlib1d", "idxlib1e", "idxlib1f"]
row2Index = ["idxlib2a", "idxlib2b", "idxlib2c", "idxlib2d", "idxlib2e", "idxlib2f"]
row1Search = ["srclib1a", "srclib1b", "srclib1c", "srclib1d", "srclib1e", "srclib1f", "srclib1g", "srclib1h",
              "srclib1i", "srclib1j", "srclib1k", "srclib1l"]
row2Search = ["srclib2a", "srclib2b", "srclib2c", "srclib2d", "srclib2e", "srclib2f", "srclib2g", "srclib2h",
              "srclib2i", "srclib2j", "srclib2k", "srclib2l"]
teNodes = ["telib1", "telib2"]


# start AIE interface
aie = start_aie()
try:
    opts, args = getopt.getopt(sys.argv[1:], "c:n:", ["command=", "node="])
    c = opts[0][1]
    n = opts[1][1]
except:
    print("  [WARNING] no options declared -- setting default values to '-c status -n ts' ")
    c = 'status'
    n = 'ts'
    pass


# status tasks
if c == 'status':
    nodes, aie = get_status(aie)
    te_count = 0
    for node in nodes:
        if n == 'ts':
            print(node + " ... " + nodes[node])
            if node not in validNodes:
                print("  [ERROR] with node %s - invalid node name" % node)
        if n == 'te':
            if node in teNodes:
                if nodes[node] != 'RUNNING':
                    te_count += 1
    if te_count == 0 and n == 'te':
        print("  [OK] TE count is all good ")
        sys.exit(0)
    elif te_count != 0 and n == 'te':
        print("  [ERROR] TE count is INVALID")
        sys.exit(2)


# stop tasks
if c == 'stop':
    nodes, aie = get_status(aie)
    if n == 'adm-te':
        manage_row(c, "processors", n)
        manage_row(c, "adm", n)
    elif n in nodes:
        if nodes[n] == "RUNNING":
            results, aie = manage_node(aie, c, n)
            stopping = 0
            i = 0
            while stopping == 0:
                nodes, aie = get_status(aie)
                if nodes[n] == "STOPPED":
                    stopping = 1
                i += 1
                msg = "\r  [Stopping %s] %s" % (n, ("#" * i))
                sys.stdout.write(msg)
                sys.stdout.flush()
                time.sleep(1)
            print(" [DONE]")
        elif nodes[n] == "STOPPED":
            print("  [WARNING] node %s appears to be already STOPPED" % n)
            sys.exit(1)
    else:
        print("  [ERROR] %s not a valid node name" % n)


# start tasks
if c == 'start':
    nodes, aie = get_status(aie)
    if n == 'adm-te':
        manage_row(c, "processors", n)
        manage_row(c, "adm", n)
    elif n in nodes:
        if nodes[n] == "STOPPED":
            results, aie = manage_node(aie, "clean", n)
            results, aie = manage_node(aie, c, n)
            starting = 0
            i = 0
            while starting == 0:
                nodes, aie = get_status(aie)
                if nodes[n] == "RUNNING":
                    starting = 1
                    i += 1
                    msg = "\r  [Starting %s] %s" % (n, ("#" * i))
                    sys.stdout.write(msg)
                    sys.stdout.flush()
                    time.sleep(1)
            print(" [DONE]")
        elif nodes[n] == "RUNNING":
            print("  [WARNING] node %s appears to be already RUNNING" % n)
            sys.exit(1)
    else:
        print("  [ERROR] %s not a valid node name" % n)


# make a clean exit if you make it here
sys.exit(0)
