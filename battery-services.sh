#!/bin/bash

SERVICES=(\
apache2 \
bluetooth \
mysql \
avahi-daemon \
)

COMMAND=$1
if [[ $COMMAND = "start" || $COMMAND = "stop" ]]
then
    echo "Starting or stopping services..."
    for i in "${SERVICES[@]}"
    do
        sudo service $i $COMMAND
    done
else
    echo "Improves battery life by stopping select services, can also restart them"
    echo "Usage: $0 [start|stop]"
fi
