import ceylon.file {
    File,
    parsePath,
    Directory,
    lines,
    Nil,
    createFileIfNil
}

Boolean ifArg(String* args)
        => args.any(process.namedArgumentPresent);

String? argVal(String* args)
        => args.map(process.namedArgumentValue).coalesced.first;

shared void run() {
    if(!ifArg("classname", "inputfile", "outdir", "c", "f", "o")) {
        help();
        return;
    }
    "Class name should be given for the root class: --classname=ClassName of -c ClassName"
    assert(exists clazzName = argVal("classname", "c"));

    "Input file should be given: --inputfile=file.json or -f file.json"
    assert(exists inputFileName = argVal("inputfile", "f"));

    "Output dir should be given: --outdir=path/to/dir or -o path/to/dir"
    assert(exists outDirName = argVal("outdir", "o"));

    "Input file should exists: ``inputFileName``"
    assert(is File inputFile = parsePath(inputFileName).resource);

    "Output dir should be dir or not exists"
    assert(is Nil|Directory resource = parsePath(outDirName).resource);

    Directory outDir = if(is Nil resource)
            then resource.createDirectory(true) else resource;

    String fileContent = "\n".join(lines(inputFile));

    Boolean isSerializable =
            ifArg("serializable", "s") then true else false;

    value classes =
            generateClasses(fileContent, clazzName, isSerializable);

    classes.each((clazzName -> classContent) {
        if(is Nil|File resource =
                outDir.childResource("``clazzName``.ceylon").linkedResource) {
            log("[``clazzName``]");
            log(classContent);
            File outFile = createFileIfNil(resource);
            try(writer = outFile.Overwriter()) {
                writer.write(classContent);
                print("File: ``outFile.path`` created!");
            }
        }
    });
}


void help() {
    print("""
             json2ceylon - utility, that generates ceylon classes from given json file.

             Usage:
             
                ceylon run ru.qdzo.ceylon.json2ceylon --classname=ClassName --inputfile=file.json --outdir=gen [-d -s]

             Available parameters:

               --classname    (-c) - class name of json root object
               --inputfile    (-f) - file with json content
               --outdir       (-o) - directory for generated ceylon classes
               --serializable (-s) - add serializable annotation (usable when classes will be used as interchange format)
               --debug        (-d) - print debug information
             """);
}

