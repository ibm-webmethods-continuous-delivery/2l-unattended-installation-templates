#!/bin/sh

docker run --detach \
 --name instana-agent \
 --volume /run/user/1000/:/var/run \
 --volume /home/webmethods/configuration-javadisable.yaml:/opt/instana/agent/etc/instana/configuration-javadisable.yaml \
 --volume /dev:/dev:ro \
 --volume /sys:/sys:ro \
 --volume /var/log:/var/log:ro \
 --volume instana-agent-data:/opt/instana/agent/etc/instana \
 --privileged \
 --net=01e2em_instana_n1 \
 --pid=host \
 --env="INSTANA_AGENT_ENDPOINT=ingress.instana.apps.ocp.linuxone.roma-port.it.ibm.com" \
 --env="INSTANA_AGENT_ENDPOINT_PORT=443" \
 --env="INSTANA_AGENT_KEY=xxxxxxxxxxxxxxxxx" \
 --env="INSTANA_DOWNLOAD_KEY=xxxxxxxxxxxxxxxxx" \
 icr.io/instana/agent
