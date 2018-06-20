#!/bin/bash

# PRE-REQ put four websites into MAINT_MODE at 6AM
echo "[PRE-REQ] bring the 4 search cluster web servers Out Of Rotation (OOR)"
echo "  To do so, run this command on 651, 652, 653 and 731 before proceeding:"
echo " "
echo " # mv /appl/tomcat0/webapps/status/status.jsp /appl/tomcat0/webapps/status/status.jsp.1"
echo " # monit restart tomcat0 "
echo " "

echo "[STEP 1] copy and paste the update_pass.sh below into root home on 651, 652, 653 and 731 "
echo " chomd a+x update_pass.sh "
echo " run ./update_pass.sh "
echo " "

echo "[STEP 2] push out the new password to the Search cluster"
echo "Run this from alpcispapp730 as search user:"
echo "  cd /appl1/libSrch/Attivio/sc_multiv42; /appl1/libSrch/Attivio/aie_4.2.0/bin/aie-cli -sc /appl1/libSrch/Attivio/sc_multiv42"
echo "Wait for the AIE console to come up and execute: "
echo "  aie> deploy force restart"
echo " "

echo "[STEP 3] restart apache, tomcat and gatekeeper services using monit command on 651, 652, 653 and 731 using:"
echo " # monit start all "
echo " # monit status all "
echo " "

echo "[POST-REQ] Now that all Attivio process are up , apache, tomcat and gatekeeper services also up. Bring server back into rotation."
echo "  To do so, run this command on 651, 652, 653 and 731 after completeion: "
echo " mv /appl/tomcat0/webapps/status/status.jsp.1 /appl/tomcat0/webapps/status/status.jsp"
echo " "

sed -i 's/^ge.db.sc.pass=*{5O2iffIPzC2YYD1ynXPrIA==}/ge.db.sc.pass=T7g_8UXnD/g' /appl1/libSrch/Attivio/sc_multiv42/agent42/projects/sc_multiv42/default/conf/properties/sc_multiv42.properties

##### update_pass.sh #####
#!/bin/bash
config_file="/appl1/libSrch/Attivio/sc_multiv42/agent42/projects/sc_multiv42/default/conf/properties/sc_multiv42.properties"

# BACKUP or die
if [ -f $config_file ]; then
    cp $config_file $config_file.bak
else
    echo "File not found! - unable to create a backup or continue"
    exit 2
fi

# BACKOUT -- swap the above IF loop with the loop below and re-run
#if [ -f $config_file ]; then
#    cp $config_file $config_file.bak
#    exit 0
#else
#    echo "File not found! - unable to create a backup or continue"
#    exit 2
#fi

# EXAMPLE of ge.db.sc.pass variable
# ge.db.sc.user=supadm01
# ge.db.sc.pass=*{5O2iffIPzC2YYD1ynXPrIA==}
#

# SRCHFRMS -- St_FPy3f27k

# new password for SUPADM01 user --- T7g_8UXnD


echo "[RUN STEP 1] updating password in agent42 configuration file on localhost ..."
sed -i 's/^ge.db.sc.pass=*{5O2iffIPzC2YYD1ynXPrIA==}/ge.db.sc.pass=T7g_8UXnD/g' ${config_file}
echo " "
echo "NEW PASSWORD saved to configuration file, double-check output here:  "
cat /appl1/libSrch/Attivio/sc_multiv42/agent42/projects/sc_multiv42/default/conf/properties/sc_multiv42.properties | grep db.sc.pass

