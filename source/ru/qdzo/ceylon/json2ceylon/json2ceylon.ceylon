import ceylon.file {
    parsePath,
    Nil,
    Directory,
    lines,
    createFileIfNil,
    File
}
import ceylon.json {
    JsonObject,
    parse
}

shared
{<String->{String[2]*}>*} generateClassInfo(
        String jsonString,
        String rootClassName) {

    "Json should have toplevel json-object"
    assert(is JsonObject obj = parse(jsonString));
    value classEmitter = Json2CeylonClassTransformer(obj ,rootClassName);
    return classEmitter.result;
}

shared
{<String->String>*} generateClasses(
        String jsonString,
        String rootClassName,
        Boolean externalizable = false) {

    return generateClassInfo(jsonString, rootClassName)
        .map(externalizable then emitExternalizableClass else emitClass);
}

shared
void json2ceylon(
        String inputFile,
        String outputDir,
        String clazzName,
        Boolean externalizable = false) {

    value jsonFile = parsePath(inputFile).resource;
    if(!is File jsonFile) {
       throw Exception("Input file should exists - ``inputFile``");
    }

    value resource = parsePath(outputDir).resource;
    if(!is Nil|Directory resource) {
       throw Exception("Output dir should be dir or not exists - ``resource``");
    }

    Directory outDir = if(is Nil resource)
    then resource.createDirectory(true)
    else resource;

    String fileContent = "\n".join(lines(jsonFile));

    value classes =
            generateClasses(fileContent, clazzName, externalizable);

    classes.each((clazzName -> classContent) {
        if(is Nil|File resource =
                outDir.childResource("``clazzName``.ceylon").linkedResource) {
            log("[``clazzName``]");
            log(classContent);
            File outFile = createFileIfNil(resource);
            try(writer = outFile.Overwriter()) {
                writer.write(generationInfo);
                writer.write(classContent);
                print("File: ``outFile.path`` created!");
            }
        }
    });
}
