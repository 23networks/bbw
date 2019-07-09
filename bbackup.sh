#!/bin/bash
chmod 700 /opt/bbackup/helpers/*
for i in /opt/bbackup/bbackup.d/*
do
  source "$i"
done
