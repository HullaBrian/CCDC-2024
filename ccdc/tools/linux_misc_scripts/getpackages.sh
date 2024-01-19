#!/bin/sh
sudo dpkg --get-selections | awk '$2=="install"{print $1}'
