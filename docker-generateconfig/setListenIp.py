#!/usr/bin/env python3
import os
import sys
import re
import yaml

envVars = dict()
if os.path.exists('.env') and os.path.getsize('.env') > 0:
    with open('.env') as file:
        for line in file:
            if line.startswith('#') or not line.strip():
                continue
            key, value = line.strip().split('=', 1)
            value = value.replace('"', '')
            if key in envVars:
                print(f"WARNING: duplicate key={key} in env file='.env'")
            envVars[key] = value
else:
    print(f"ERROR: file='.env' not found or size=0")
    exit(1)

inputYamlFile = sys.argv[1]
outputYamlFile = sys.argv[2]
externalListenHosts = envVars.get('EXTERNAL_LISTEN_HOSTS', '').split()

listenHosts = list()
for host in externalListenHosts:
    if host not in listenHosts:
        listenHosts.append(host)

with open(inputYamlFile, 'r') as file:
    config = yaml.load(file, Loader=yaml.Loader)

for index, nodes in enumerate(config['nodes']):
    listenHost = nodes['addresses'][0].split(':')[0]
    listenPort = nodes['addresses'][0].split(':')[1]
    nodeListenHosts = [listenHost] + listenHosts
    for nodeListenHost in nodeListenHosts:
        listenAddress = nodeListenHost + ':' + str(listenPort)
        if listenAddress not in nodes['addresses']:
            nodes['addresses'].append(listenAddress)
        for name, value in envVars.items():
            if re.match(r"^(ANY_SYNC_.*_PORT)$", name) and value == listenPort:
                if re.match(r"^(ANY_SYNC_.*_QUIC_PORT)$", name):
                    continue
                quicPortKey = name.replace('_PORT', '_QUIC_PORT')
                if quicPortKey in envVars:
                    quicPortValue = envVars[quicPortKey]
                    quicListenAddress = 'quic://' + nodeListenHost + ':' + str(quicPortValue)
                    if (quicPortValue) and (quicListenAddress not in nodes['addresses']):
                        nodes['addresses'].append(quicListenAddress)

with open(outputYamlFile, 'w') as file:
    yaml.dump(config, file)
