#!/bin/bash

function enable-service {
    systemctl enable $1
    systemctl start $1
}

[ -f "/usr/bin/thermald" ]  && enable-service "thermald.service"
[ -f "/usr/bin/ntpd" ]      && enable-service "ntpd.service"