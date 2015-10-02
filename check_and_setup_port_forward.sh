#!/bin/bash

if [ $# -lt 3 ]; then
echo "Usage: ./setup_all_jolokia_ports.sh app lifecycle gearid"
 echo "    eg: \" ./setup_all_jolokia_ports.sh app1 prod 55107a94536c23098c0000aa\""
 exit 1
fi

echo "NOTE: If the command appears to be hung (more than 60 sec) then kill it (Ctrl+c) and run 'rhc account' from the command prompt and then rerun this script."

#Add applications to this associative array  
appid[app1~dev]=" -a app1 -n domain1 "
appid[app1~stage]=" -a app2 -n domain2 "
appid[app1~prod]=" -a app3 -n domain3 "

mkdir -p tmp
lifecycle=$2
app=$1
gearid=$3

port_mapping_file="tmp/portmapping.$app.$lifecycle.$gearid.txt"
touch $port_mapping_file

declare -A portmappings

setup_port_forward()
{
  app=$1
  lifecycle=$2
  appid=${appid["$1~$2"]}
  gearname=$3
  JOLOKIA_PORT=
  rm -rf tmp/out.$app.$lifecycle.$gearid.log
  rhc port-forward $appid -g $gearname > tmp/out.$app.$lifecycle.$gearid.log &
  echo "Port forward being setup for $app in $lifecycle for $gearname. This will take some time..."
  sleep 30s
  cat tmp/out.$app.$lifecycle.$gearid.log 
  JOLOKIA_PORT=$(cat tmp/out.$app.$lifecycle.$gearid.log | grep -i "=>" | grep -i 10151 | tr -s ' '| cut -d' ' -f2)
  if [ -z $JOLOKIA_PORT ]; then
    kill $!
  else
    JOLOKIA_DESCRPTION=$(curl -s -m 60 http://$JOLOKIA_PORT/jolokia/version | ./json | grep -i "\"value\",\"config\",\"agentDescription\"" | cut -d'"' -f8 )
    if [ ! -z JOLOKIA_DESCRPTION ]; then
      portmappings[$JOLOKIA_DESCRPTION]="$JOLOKIA_PORT"
    fi
  fi
}

port_mapping_valid()
{
  JOLOKIA_DESCRPTION=$(curl -s -m 60 http://$1/jolokia/version | ./json | grep -i "\"value\",\"config\",\"agentDescription\"" | cut -d'"' -f8 )
  if [ "$JOLOKIA_DESCRPTION" == "$2.$3.$4" ]; then
    return 0;
  else
    return 1;
  fi
  return 2;
}

line=$(cat $port_mapping_file)
if [[ $line ]]; then
 portmappings[$(echo $line | cut -d'~' -f1)]=$(echo $line | cut -d'~' -f2)
fi

existing_port_mapping=${portmappings[$app.$lifecycle.$gearid]}

if [ ! -z $existing_port_mapping ]; then
 echo "Existing port mapping found: $existing_port_mapping $app $lifecycle $gearid. Checking validity..."
 port_mapping_valid  $existing_port_mapping $app $lifecycle $gearid

 if [ $? -ne 0 ]; then
  echo "Existing port mapping invalid. Recreating port forward for $app $lifecycle $gearid ..."
  setup_port_forward $app $lifecycle $gearid
 fi
else 
 echo "Existing port mapping not found. Setting up fresh port forward for $app $lifecycle $gearid ..."
 setup_port_forward $app $lifecycle $gearid
fi

cat /dev/null > $port_mapping_file
for i in "${!portmappings[@]}"
do
  echo "Port Forward setup: $i~${portmappings[$i]}"
  echo "$i~${portmappings[$i]}" > $port_mapping_file
  exit 0
done
echo "Port forward not set"
exit 107


