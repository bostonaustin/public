#!/usr/bin/env python


"""
GE Search AIE Manager tool

Usage:  aieManager.py -c [status|start|stop|restart] -n [ts|te|node_name|adm-te|all]
        aieManager.py -c status -n [ts|te] (troubleshoot|te-count)
        aieManager.py -c start -n [node_name|adm-te|te] (srclib1a | adm & TE processors)
        aieManager.py -c restart -n [node_name|adm-te|te|row1|row2] (srclib1a | adm & TE processors)

            $ aieManager.py -c restart -n adm-te

NOTES:
- DONE - add a restart option to combine stop + start
            ok - works as expected for te, row1, row2, admte

- DONE - remove row functions and add status to node functions
            separated out into node restart since nodeset by-passes timeout and dies

- DONE - p.expect TIMEOUT vs. timeout=300
            works ok -- but still not triggered at 180

TODO -- send an email that the script failed and one node is in DIED status - IF cron

TODO -- add a config backup option
"""


import pexpect
import sys
import time
import re
import getopt
import os


# constants
validNodes = ["adm", "idxlib1a", "idxlib1b", "idxlib1c", "idxlib1d", "idxlib1e", "idxlib1f", "idxlib2a",
              "idxlib2b", "idxlib2c", "idxlib2d", "idxlib2e", "idxlib2f", "srclib1a", "srclib1b", "srclib1c",
              "srclib1d", "srclib1e", "srclib1f", "srclib1g", "srclib1h", "srclib1i", "srclib1j", "srclib1k",
              "srclib1l", "srclib2a", "srclib2b", "srclib2c", "srclib2d", "srclib2e", "srclib2f", "srclib2g",
              "srclib2h", "srclib2i", "srclib2j", "srclib2k", "srclib2l", "telib1", "telib2", "perfmon",
              "store", "null"]
row1Search = ["srclib1a", "srclib1b", "srclib1c", "srclib1d", "srclib1e", "srclib1f", "srclib1g", "srclib1h",
              "srclib1i", "srclib1j", "srclib1k", "srclib1l"]
row2Search = ["srclib2a", "srclib2b", "srclib2c", "srclib2d", "srclib2e", "srclib2f", "srclib2g", "srclib2h",
              "srclib2i", "srclib2j", "srclib2k", "srclib2l"]
row1Index = ["idxlib1a", "idxlib1b", "idxlib1c", "idxlib1d", "idxlib1e", "idxlib1f"]
row2Index = ["idxlib2a", "idxlib2b", "idxlib2c", "idxlib2d", "idxlib2e", "idxlib2f"]
validStatus = ["RUNNING", "STOPPED", "STOPPING", "STARTING", "DIED", "NOT_STARTED"]
admNodes = ["adm", "telib1", "telib2"]
teNodes = ["telib1", "telib2"]


# functions
def usage():
    """prints out the command help / usage message"""
    print("Usage: aieManager.py -c [status|start|stop|restart] -n [ts|te|node_name|adm-te|all]")
    print("        aieManager.py -c status -n [ts|te] (troubleshoot|te-count)")
    print("        aieManager.py -c start -n [node_name|adm-te|te] (srclib1a | adm & TE processors)")
    print("        aieManager.py -c restart -n [node_name|adm-te|te|row1|row2] (srclib1a | adm & TE processors) \n")
    print("        $ aieManager.py -c restart -n adm-te ")


def start_aie():
    """starts up the AIE manager"""
    os.chdir('/appl1/libSrch/Attivio/sc_multiv42')
    # aie = pexpect.spawn('/appl1/libSrch/Attivio/aie_4.2.0/bin/aie-cli -sc /appl1/libSrch/Attivio/sc_multiv42',
    #                    timeout=300)
    aie = pexpect.spawn('/appl1/libSrch/Attivio/aie_4.2.0/bin/aie-cli -sc /appl1/libSrch/Attivio/sc_multiv42')
    aie.expect('aie>')
    return aie


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


def main(aie, c, n):
    """runs the main logic"""
    if c == 'status':
        te_count = 0
        for node in nodes:
            if n == 'ts':
                if node not in validNodes:
                    print("  [ERROR] with node %s - invalid node name" % node)
                    sys.exit(2)
                else:
                    print(node + " ... " + nodes[node])
            if n == 'te':
                if node in teNodes:
                    if nodes[node] != 'RUNNING':
                        te_count += 1
                        sys.exit(0)
        if te_count == 0 and n == 'te':
            print("  [OK] TE count is all good ")
            sys.exit(0)
        elif te_count != 0 and n == 'te':
            print("  [ERROR] TE count is INVALID")
            sys.exit(2)
    elif c == 'stop':
        if n == 'adm-te':
            for n in admNodes:
                stop_node(aie, n)
        elif n == 'te':
            for n in teNodes:
                stop_node(aie, n)
        elif n == 'all':
            for n in nodes:
                stop_node(aie, n)
        elif n == 'row1':
            for n in row1Index, row1Search:
                stop_node(aie, n)
        elif n == 'row2':
            for n in row2Index, row2Search:
                stop_node(aie, n)
        elif n in nodes:
            stop_node(aie, n)
    # start
    elif c == 'start':
        if n == 'adm-te':
            for n in admNodes:
                start_node(aie, n)
        elif n == 'te':
            for n in teNodes:
                start_node(aie, n)
        elif n == 'all':
            for n in nodes:
                start_node(aie, n)
        elif n == 'row1':
            for n in row1Index, row1Search:
                start_node(aie, n)
        elif n == 'row2':
            for n in row2Index, row2Search:
                start_node(aie, n)
        elif n in nodes:
            start_node(aie, n)
    # restart
    elif c == 'restart':
        if n == 'adm-te':
            for n in admNodes:
                restart_node(aie, n)
        elif n == 'te':
            for n in teNodes:
                restart_node(aie, n)
        elif n == 'all':
            for n in nodes:
                restart_node(aie, n)
        elif n == 'row1':
            for n in row1Index, row1Search:
                restart_node(aie, n)
        elif n == 'row2':
            for n in row2Index, row2Search:
                restart_node(aie, n)
        elif n in nodes:
            restart_node(aie, n)
    # deploy
    elif c == 'deploy':
        deploy_project()
    # die if all else fails
    else:
        print("  [ERROR] %s not a valid node name - main failed" % n)
        sys.exit(2)
    sys.exit(0)


def manage_node(aie, c, n):
    """inserts the proper syntax for aie> command on a node"""
    aie.sendline('%s node %s' % (c, n))
    aie.expect('aie>')
    results = aie.before
    return results, aie


def kill_node(aie, n):
    """kills the node process immediately w/o shutting down"""
    aie.sendline('kill node %s' % n)
    aie.expect('aie>')
    results = aie.before
    return results, aie


def start_node(aie, n):
    """visual status progress of starting process"""
    manage_node(aie, "start", n)
    count = 1
    is_starting = True
    while is_starting is True:
        time.sleep(5)
        nodes, aie = get_status(aie)
        if nodes[n] == "STARTING":
            msg = "\r  [Starting %s] %s" % (n, ("#" * count))
            sys.stdout.write(msg)
            sys.stdout.flush()
            time.sleep(60)
            count += 1
        elif nodes[n] == "RUNNING":
            print("  [DONE] %s is RUNNING" % n)
            break
        elif nodes[n] == "STOPPED":
            print("  [WARNING] node %s is STOPPED - attempting to start again" % n)
            if count < 5:
                manage_node(aie, "start", n)
                time.sleep(60)
                count += 1
            else:
                kill_node(aie, n)
                # wait_until_running(aie, n)
        elif nodes[n] == "STOPPING":
            print("  [ERROR] node %s is STOPPING " % n)
            if count < 5:
                # manage_node(aie, "start", n)
                time.sleep(60)
                count += 1
            else:
                kill_node(aie, n)
            # wait_until_stopped(aie, n)
        elif nodes[n] == "DIED":
            print("\n  [ERROR] node %s has DIED \n" % n)
            sys.exit(2)
            # manage_node(aie, "start", n)
        else:
            break


def stop_node(aie, n):
    """visual status progress of stopping process"""
    manage_node(aie, "stop", n)
    count = 1
    is_stopping = True
    while is_stopping is True:
        time.sleep(5)
        nodes, aie = get_status(aie)
        if nodes[n] == "STOPPING":
            msg = "\r  [Stopping %s] %s" % (n, ("#" * count))
            sys.stdout.write(msg)
            sys.stdout.flush()
 #           continue
        elif nodes[n] == "STOPPED":
            print("  [DONE] %s is STOPPED" % n)
            break
        elif nodes[n] == "RUNNING":
            manage_node(aie, "stop", n)
            wait_until_stopped(aie, n)
        elif nodes[n] == "STARTING":
            print("  [ERROR] node %s is STARTING " % n)
            wait_until_running(aie, n)
        elif nodes[n] == "DIED":
            print("\n  [ERROR] node %s has DIED \n" % n)
        else:
            break
        time.sleep(60)
        count += 1


def restart_node(aie, n):
    """stop and start a RUNNING node --OR-- starts a STOPPED node"""
    if nodes[n] == "RUNNING":
        stop_node(aie, n)
        time.sleep(3)
        wait_until_stopped(aie, n)

        # clean_node(aie, n)
        aie.sendline('clean %s' % n)
        print("  [CLEAN] ### [DONE] %s has been cleaned]" % n)

        time.sleep(3)
        start_node(aie, n)
        #wait_until_running(aie, n)
    elif nodes[n] == "STOPPED":
        start_node(aie, n)
        #wait_until_running(aie, n)
    elif nodes[n] == "STARTING":
        wait_until_running(aie, n)
    elif nodes[n] == "STOPPING":
        wait_until_stopped(aie, n)
    elif nodes[n] == "DIED":
        print("\n  [ERROR] node %s has DIED - attempting to start again \n" % n)
        start_node(aie, n)


def wait_until_running(aie, n):
    """waits for nodes starting to finish or kills the node process immediately w/o shutting down"""
    mins_run = 0
    while mins_run < 5:
        mins_run += 1
        if mins_run >= 2:
            time.sleep(60)
        nodes, aie = get_status(aie)
        if nodes[n] == "RUNNING":
            print("  [DONE] successfully started node %s " % n)
            break
        elif nodes[n] == "STOPPED":
            if mins_run < 1:
                manage_node(aie, "start", n)
            else:
                kill_node(aie, n)
        elif nodes[n] == "STARTING":
            pass
        elif nodes[n] == "STOPPING":
            kill_node(aie, n)
            show_stopping(aie, n)
        elif nodes[n] == "DIED":
            print("\n  [ERROR] node %s has DIED " % n)


def wait_until_stopped(aie, n):
    """waits for stopping processes to finish or kills the node after timeout"""
    mins_run = 0
    while mins_run < 5:
        mins_run += 1
        if mins_run >= 2:
            time.sleep(60)
        nodes, aie = get_status(aie)
        if nodes[n] == "STOPPED":
            print("  [DONE] successfully stopped node %s " % n)
            break
        elif nodes[n] == "RUNNING":
            if mins_run < 1:
                manage_node(aie, "stop", n)
            else:
                kill_node(aie, n)
        elif nodes[n] == "STARTING":
            kill_node(aie, n)
        elif nodes[n] == "STOPPING":
            pass
        elif nodes[n] == "DIED":
            print("\n  [ERROR] node %s has DIED " % n)


def deploy_project():
    """pushes out the config to the cluster - i.e. DB / Oracle password update"""
    aie.sendline('deploy force restart')
    aie.expect('aie>')
    results = aie.before
    return results, aie


# MAIN
aie = start_aie()
nodes, aie = get_status(aie)
try:
    opts, args = getopt.getopt(sys.argv[1:], "c:n:", ["command=", "node="])
    c = opts[0][1]
    n = opts[1][1]
except:
    """ if no options are declared - print a summary as the default """
    c = 'status'
    n = 'ts'
    pass
main(aie, c, n)
