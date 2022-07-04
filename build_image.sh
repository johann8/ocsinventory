#!/bin/bash

# set variables
_VERSION=1.0.4

# create build
docker build -t johann8/ocsinventory:${_VERSION} .
_BUILD=$?
if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a 
   docker tag johann8/ocsinventory:${_VERSION} johann8/ocsinventory:latest
fi

#push image to dockerhub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/ocsinventory:latest
   _PUSH=$?
   docker push johann8/ocsinventory:${_VERSION}
   _PUSH1=$?
   docker images -a |grep ocsinventory
fi

#delete build
if [ ${_PUSH} = 0 ] && [ ${_PUSH1} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/ocsinventory:latest
   #docker images -a
   docker rmi johann8/ocsinventory:${_VERSION}
   #docker images -a
   docker rmi centos:centos7 
   docker images -a
fi
