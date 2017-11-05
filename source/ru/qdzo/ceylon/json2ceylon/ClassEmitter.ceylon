import ceylon.collection {
    ArrayList
}
import ceylon.file {
    parsePath,
    File,
    Nil,
    Directory,
    lines,
    createFileIfNil
}
import ceylon.json {
    Visitor,
    JsonObject,
    parse,
    visit
}

// SUPER LOGGER
Anything(String) log
        = ifArg("debug", "d") then process.writeLine else noop;

shared String->String printClass(String->{[String, String]*} classInfo) {
    value builder = StringBuilder();
    value className->fields = classInfo;
    function fieldTemplate(String[2] field) => "shared ``field[0]`` ``field[1]``";
    builder.append("shared class ``className``(\n   ");
    builder.append(",\n    ".join(fields.map(fieldTemplate)));
    builder.append("\n) {}");
    return className->builder.string;
}

String makeClazzName(String str)
        => str[0..0].uppercased + (str.endsWith("s") then str[1..str.size-2] else str.rest);
String makeFieldName(String str) => str[0..0].lowercased + str.rest;

shared class ClassEmitter(String topLevelClassName) satisfies Visitor {

    class ClassInfoCollecttor(className) {
        variable {[String,String]*} _fields = {};
        variable Boolean enabled = true;
        shared String className;
        shared {[String,String]*} fields => _fields;

        shared void disable() => enabled = false;
        shared void enable() => enabled = true;

        shared default void add(String[2] field){
            if(enabled) {
                _fields = _fields.chain { field };
            }
        }
    }

    object fakeInfoCollector extends ClassInfoCollecttor(""){
        shared actual void add(String[2] field) => noop();
    }

//    MutableMap<String, {[String,String]*}> _result = HashMap<String, {[String,String]*}>{};
    variable { <String->{[String,String]*}>*} _result =  {};
    shared {<String->{[String,String]*}>*} result => _result;

    ArrayList<ClassInfoCollecttor> state = ArrayList<ClassInfoCollecttor>{};


    ArrayList<Boolean> level = ArrayList<Boolean>{};

    variable String? currentKey = topLevelClassName;
    String ckey => currentKey else "";
    void clearKey() => currentKey = null;

    value isObjectLevel => level.last else true;
    value isArrayLevel => !isObjectLevel;

    variable Integer needToCaptureValues = 0;
    value isNeedToCapture => needToCaptureValues > 0;
    void needToCapture() => needToCaptureValues++;
    void captureVal() => needToCaptureValues--;

    void push(Boolean isObject) {

        if(level.empty, state.empty) {
            value clazzName = makeClazzName(ckey);
            log("state [] new classCollector: ``clazzName``");
            state.add(ClassInfoCollecttor(clazzName));
            level.push(isObject);
            return;
        }

        assert(exists lastLevel = level.last);
        switch([lastLevel, isObject])
        case([true, true]) {
            value clazzName = makeClazzName(ckey);
            log("state [] new classCollector: ``clazzName``");
            state.add(ClassInfoCollecttor(clazzName));
        }
        case([true, false]) {
            needToCapture();
        }
        case([false, true]) {
            if(isNeedToCapture) {
                value clazzName = makeClazzName(ckey);
                log("state [] new classCollector: ``clazzName``");
                state.add(ClassInfoCollecttor(clazzName));
            } else {
                state.add(fakeInfoCollector);
            }
        }
        case([false, false]) {
        }
        else {
            "Unbelievable"
            assert(false);
        }
        level.push(isObject);
        log("state [] classCollector: ``state.size``, level: ``level.size``");
    }

    void pop() {
        assert(exists curLevel = level.last,
               exists classCollector = state.last);

        value prevLevel = level.exceptLast.last else true;

        switch([prevLevel, curLevel])
        case([true, true]) {
            _result = _result.chain { classCollector.className->classCollector.fields };
            state.pop();
        }
        case([true, false]) {
            if(!isNeedToCapture) {
                log("ENABLE PRINT");
                state.last?.enable();
            }
        }
        case([false, true]) {
            if(isNeedToCapture){
                _result = _result.chain { classCollector.className->classCollector.fields };
                captureVal();
                state.pop();
                log("DISABLE PRINT");
                state.last?.disable();
            } else {
                state.pop();
            }
        }
        case([false, false]) {
        }
        else {
            "Unbelievable"
            assert(false);
        }
        level.pop();
        log("state [] classCollector: ``state.size``, level: ``level.size``");
    }


    void performAddField(String fieldType, String field) {
        if(exists classCollector = state.last) {
            log("performAddField >> \"``string``\"");
            classCollector.add([fieldType, field]);
        }
    }

    void addField(String fieldType) {
        value clazz = makeClazzName(fieldType);
        value field = makeFieldName(ckey);
        if(isArrayLevel) {
            performAddField("[``clazz``*]", field);
        }  else  {
            performAddField(clazz, field);
        }
        if(isArrayLevel, isNeedToCapture) {
            captureVal();
            state.last?.disable();
        }
    }

    shared actual void onStartObject(){
        log("event -> onStartObject");
        addField(ckey);
        push(true);
        clearKey();
    }

    shared actual void onKey(String key) {
        log("event -> onKey: \"``key``\"");
        currentKey = key;
    }

    shared actual void onEndObject() {
        log("event -> onEndObject");
        pop();
    }

    shared actual void onStartArray(){
        log("event -> onStartArray");
        push(false);
    }

    shared actual void onEndArray() {
        log("event -> onEndArray");
        pop();
    }

    shared actual void onString(String s){
        log("event -> onString");
        addField("String");
        clearKey();
    }

    shared actual void onNumber(Integer|Float n) {
        log("event -> onNumber");
        addField(if(is Integer n) then "Integer" else "Float");
        clearKey();
    }

    shared actual void onBoolean(Boolean v) {
        log("event -> onBoolean");
        addField("Boolean");
        clearKey();
    }

    shared actual void onNull() {
        log("event -> onNull");
        addField("String?"); // assume that field is string
        clearKey();
    }
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
    return classEmitter.result.map(printClass);
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
