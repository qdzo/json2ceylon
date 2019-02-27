#!/usr/bin/env bash

echo "Generate externalizable classes"
echo "ceylon run ru.qdzo.ceylon.json2ceylon/0.0.2-SNAPSHOT --inputfile=user.json --outdir=gen_ext --classname=User -e"
ceylon run ru.qdzo.ceylon.json2ceylon/0.0.2-SNAPSHOT --inputfile=user.json --outdir=gen_ext --classname=User -e
