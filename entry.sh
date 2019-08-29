#!/bin/bash
_term() { 
  echo "Caught SIGTERM signal! Sending SIGINT to $child"
  kill -INT "$child"

  while kill -0 "$child" 2> /dev/null; do
    sleep 0.25
  done
}

trap _term SIGTERM
trap _term SIGINT

echo "Starting..."
echo "Resolution is $VNC_RES"
echo "Password is $PASSWORD"

touch /root/init.sh
/root/init.sh

/usr/bin/supervisord --nodaemon &
child=$! 
wait "$child"