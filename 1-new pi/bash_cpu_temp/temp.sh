#!/bin/bash - 
#===============================================================================
#
#          FILE: temp.sh
# 
#         USAGE: ./temp.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Yehun (), yehunhk@163.com
#  ORGANIZATION: Yehun
#       CREATED: 03/09/2018 01:40:25 PM
#      REVISION:  ---
#===============================================================================

cat /sys/class/thermal/thermal_zone0/temp | awk '{print "CPU Temp:"(int($0) / 1000)}'
/opt/vc/bin/vcgencmd measure_temp | cut -c6-9 | awk '{print "CPU Temp:"$0}'
