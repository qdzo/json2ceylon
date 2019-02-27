Ceylon2Json - Ceylon CLI-utility to generate ceylon classes from json file
---

Simple tool which can generate ceylon classes from single deeply-nested json file.

Examples you can find in examples directory

# Instalation

Module is not published to ceylon-herd yet and has only local installation instructions.

## Requirenments

- JDK8
- Ceylon 1.3.3
- ant >= 1.9

> All you can install via [SDKMAN](https://sdkman.io/)


## Instructions

Two main installation instructions

- as ceylon module
- as ceylon CLI plugin


Ceylon default installation (publish to *USER* - local ceylon-repo)

    ant publish

Installation as ceylon plugin

    ant install-plugin


# Usage

Ceylon CLI Usage


    json2ceylon - utility, that generates ceylon classes from given json file.
    Usage:
       ceylon run ru.qdzo.ceylon.json2ceylon --classname=ClassName --inputfile=file.json --outdir=gen [-d -e]
    Available parameters:
      --classname      (-c) - class name of json root object
      --inputfile      (-f) - file with json content
      --outdir         (-o) - directory for generated ceylon classes
      --externalizable (-e) - create externalizable class with embedded json parsing/emitting
      --debug          (-d) - print debug information


Ceylon CLI plugin usage

      ceylon json-2-ceylon [--externalizable] input-file output-dir classname

      Example:  ceylon json-2-ceylon file.json out_dir \"RootClassName\"


# LICENCE

Distributed under the Apache License, Version 2.0.
