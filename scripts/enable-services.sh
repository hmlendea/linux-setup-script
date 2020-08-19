#!/bin/bash

function enable-service {
    sudo systemctl enable $1
    sudo systemctl start $1
}

enable-service "thermald.service"
