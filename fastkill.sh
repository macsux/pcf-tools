#!/bin/bash
if [[ ($1 == "start") || ($1 == "stop" ) ]]
        then
                echo "Running PCF $1 Process (warning: this toggles director resurrection off/on!)..."
        else
                echo "Usage: $0 [shut|start|shutall] ENV_ALIAS"
                exit 1
fi

stop() {
  ENV=$1
  deployments=$(bosh2 -e $ENV deployments --json | jq .Tables[].Rows[].name)

  bosh2 -e $ENV update-resurrection off
  for deployment in $deployments; do
    vmCIDs=$(bosh2 -e $ENV -d $deployment vms --json | jq .Tables[].Rows[].vm_cid | tr -d '"')
    for cid in $vmCIDs; do
      bosh2 -e $ENV -d $deployment delete-vm $cid -n &
    done
  done
  echo "Kill VM tasks scheduled, execing 'watch bosh tasks --no-filter' to track progress"
  watch bosh2 -e $ENV tasks
}

start(){
  ENV=$1
  bosh2 -e $ENV update-resurrection on
}

if [ $1 == "start" ]; then
  start $2 
fi
if [ $1 == "stop" ]; then
  stop $2
fi
