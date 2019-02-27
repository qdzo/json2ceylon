#!/usr/bin/env bash

echo "Generate classes"
echo "ceylon run ru.qdzo.ceylon.json2ceylon/0.0.2-SNAPSHOT --inputfile=user.json --outdir=gen --classname=User"
ceylon run ru.qdzo.ceylon.json2ceylon/0.0.2-SNAPSHOT --inputfile=user.json --outdir=gen --classname=User
