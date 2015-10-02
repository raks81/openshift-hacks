# openshift-hacks
This repo contains some scripts and hacks I have used for monitoring tomcat (jbossews) based openshift applications in a private cloud. It uses jolokia for insight into the JVM and some bash scripts using the rhc commands to interact with the openshift gears.

### Enabling jolokia
Jolokia agent can be enabled on a gear by adding the snippet to JAVA_OPTS_EXT. This can be done by adding it to the action hook script of the gear:

```export  JAVA_OPTS_EXT="${JAVA_OPTS_EXT} -javaagent:$HOME/app-root/dependencies/jolokia/jolokia-jvm-1.2.3-agent.jar=host=$OPENSHIFT_JBOSSEWS_IP,agentDescription=$APP_NAME.$LIFECYCLE.$OPENSHIFT_GEAR_UUID,port=10151"```

### Setting up port forward
Once jolokia is enabled on the gear, we can use HTTP interface to access the MBeans of the JVM. However since openshift gears listen on local IP address of the host they are running on it may not be possible to access the ports directly from a client machine. Openshift provides a workaround by allowing port forwarding from the host where the gear is running into the client machine. 

Port forward can be setup using this rhc command:
```rhc port-forward $appid -g $gearname```

### Keeping the port forward alive
The problem with the above approach is that there are a variety of scenarios where the port forward can become invalid. It could be when the gear is restarted, network issues etc. In order to keep the port forward alive we need to periodically check if the port forward is valid and recrete it if needed. The ```check_and_setup_port_forward.sh``` script in the repository takes care of this by setting up the port forward and recreated the port forward if it is invalid. The script can be setup as a cron job at an appropriate interval. 



