
FOR %%F IN (
_version.lc
espConfig.lc
mqttWifi.lc
startup.lc
tftNode.lc
) DO (
	nodemcu-tool.cmd download %%F
)