Ceylon2Json - Ceylon CLI-Tool to generate ceylon classes from json file
---

Simple tool which can generate ceylon classes from single deeply-nested json file.

Examples you can find in [**examples** ](https://github.com/qdzo/json2ceylon/tree/master/examples) directory

## Installation

Module is not published to ceylon-herd yet, and has only local installation instructions.

### Requirenments

- git
- JDK8 (Ceylon 1.3.3 not working with JDK version >8)
- Ceylon 1.3.3
- ant >= 1.9

> You can install jdk, ceylon and ant via [SDKMAN](https://sdkman.io/)


### Instructions

Clone and enter project

    git clone https://github.com/qdzo/json2ceylon json2ceylon
    cd json2ceylon

Two main installation methods

- as ceylon module
- as ceylon CLI plugin


Ceylon default installation (publish to **USER** - local ceylon-repo)

    ant publish

Installation as ceylon plugin

    ant install-plugin


## Usage

Usage vary on installation method, and every method has it's strong and weak points.

- Default installation has adantages in help message and cmd options,
  but requires full module name and named-arguments
- Plugin installation provides more obscure help message, but has more short command


Ceylon default installation usage

    json2ceylon - utility, that generates ceylon classes from given json file.
    Usage:
       ceylon run ru.qdzo.ceylon.json2ceylon --classname=ClassName --inputfile=file.json --outdir=gen [-d -e]
    Available parameters:
      --classname      (-c) - class name of json root object
      --inputfile      (-f) - file with json content
      --outdir         (-o) - directory for generated ceylon classes
      --externalizable (-e) - create externalizable class with embedded json parsing/emitting
      --debug          (-d) - print debug information


Ceylon plugin usage

      ceylon json-2-ceylon [--externalizable] input-file output-dir classname

      Example:  ceylon json-2-ceylon file.json out_dir \"RootClassName\"


## Licence

Distributed under the Apache License, Version 2.0.
