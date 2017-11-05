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
    parse,
    visit
}

shared
{<String->String>*} generateClasses(
        String jsonString,
        String rootClassName,
        Boolean serialazable = false) {

    "Json should have toplevel json-object"
    assert(is JsonObject obj = parse(jsonString));
    value classEmitter = ClassEmitter(rootClassName);
    visit(obj, classEmitter);
    return classEmitter.result.map(printClass(serialazable));
}

shared
void json2ceylon(
        String inputFile,
        String outputDir,
        String clazzName,
        Boolean serializable = false) {

    "Input file should exists: ``inputFile``"
    assert(is File jsonFile = parsePath(inputFile).resource);

    "Output dir should be dir or not exists"
    assert(is Nil|Directory resource = parsePath(outputDir).resource);

    Directory outDir = if(is Nil resource)
    then resource.createDirectory(true)
    else resource;

    String fileContent = "\n".join(lines(jsonFile));

    value classes =
            generateClasses(fileContent, clazzName, serializable);

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
