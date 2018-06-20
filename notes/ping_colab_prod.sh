#!/bin/bash

#decomm_servers="cihcisdapp809v cihcisdapp737v cihcisdapp738 cihcisdapp835 cihcissapp890v cihcissapp891v cihcissapp892v cihcissapp893v cihcissapp991 cihcissapp990 alpcispapp684v alpcispapp685v alpcispapp686v alpcispapp687v alpcispapp701v alpcispapp702v alpcispapp703v alpcispapp704v loncispapp319v loncispapp320v sincispapp307v sincispapp308v blrcispcdn001 blrcispcdn002 alpcispapp730 alpcispapp731 alpcispapp760 alpcispapp767"

decomm_servers="alpcispapp848v alpcispapp586v loncispapp319v alpcispapp847v alpcispapp820v gisecpsolr01 gisecpnfs01 alpcispdb818v alpcispmq824v alpcispapp686v alpcispdb817v alpcispmq823v alpcispdb815v alpcispapp907v gisecpaplb02 alpcispapp821v gisecpofire01 gisecpquad01 gisecporadb01 alpcispmq822v alpcispapp704v sincispapp307v gisecprdf01 alpcispapp819v cihcispmqa24v alpcispdb816v gisecpcup01 sincispapp308v loncispapp320v sincispapp306v alpcispapp702v alpcispapp684v alpcispdb814v"

if [[ -e /tmp/ping-server-list.tmp ]]
      then
        echo "[ERROR] ping server list is already running ... exiting"
          exit 2
          else
                if [ -f /junk.txt ]
                      then
                          cat /junk.txt > /tmp/ping-server-list.tmp
                            fi
                              # run a ping loop
                                for decomm_server in $decomm_servers
                                      do
                                              #echo "-----------------------------------------------------------"
                                                  #echo "ping test-ing $decomm_server ..."
                                                      ping -c 1 -q ${decomm_server} > /dev/null 2>&1
                                                          if [ $? != 0 ]; then
                                                                    #echo ""
                                                                          echo "$decomm_server is DOWN"
                                                                              else
                                                                                        #echo ""
                                                                                              echo "$decomm_server is UP"  
                                                                                                  fi
                                                                                                    done
                                                                                                      rm -f /tmp/ping-server-list.tmp
                                                                                                      fi
                                                                                                      exit 0
