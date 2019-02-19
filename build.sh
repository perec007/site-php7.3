#!/bin/bash -ex
registry=casp/site-php7.3
time docker build $1 -t $registry . &&  time docker push $registry

