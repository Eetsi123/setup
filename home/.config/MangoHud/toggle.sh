#!/bin/bash
CONFIG="$(dirname $0)/MangoHud.conf"
VALUE="$(rg -oP "no_display=\K[01]" $CONFIG)"

sed -i "s/no_display=$VALUE/no_display=$((! $VALUE))/" $CONFIG
