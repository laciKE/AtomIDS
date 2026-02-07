#!/bin/sh

suricata-update -q --reload-command "suricatasc -c ruleset-reload-nonblocking"
