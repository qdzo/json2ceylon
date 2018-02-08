Boolean ifArg(String* args)
        => args.any(process.namedArgumentPresent);

String? argVal(String* args)
        => args.map(process.namedArgumentValue).coalesced.first;

shared void run() {
    testFN();
//    if(!ifArg("classname", "inputfile", "outdir", "c", "f", "o")) {
//        help();
//        return;
//    }
//
//    "Class name should be given for the root class: --classname=ClassName of -c ClassName"
//    assert(exists clazzName = argVal("classname", "c"));
//
//    "Input file should be given: --inputfile=file.json or -f file.json"
//    assert(exists inputFileName = argVal("inputfile", "f"));
//
//    "Output dir should be given: --outdir=path/to/dir or -o path/to/dir"
//    assert(exists outDirName = argVal("outdir", "o"));
//
//    Boolean externalizable =
//            ifArg("externalizable", "e") then true else false;
//
//    json2ceylon {
//        inputFile = inputFileName;
//        outputDir = outDirName;
//        clazzName = clazzName;
//        externalizable = externalizable;
//    };

}


void help() {
    print("""
             json2ceylon - utility, that generates ceylon classes from given json file.

             Usage:

                ceylon run ru.qdzo.ceylon.json2ceylon --classname=ClassName --inputfile=file.json --outdir=gen [-d -e]

             Available parameters:

               --classname      (-c) - class name of json root object
               --inputfile      (-f) - file with json content
               --outdir         (-o) - directory for generated ceylon classes
               --externalizable (-e) - create externalizable class with embedded json parsing/emitting
               --debug          (-d) - print debug information
             """);
}

