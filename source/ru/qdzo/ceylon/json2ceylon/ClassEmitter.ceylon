import ceylon.collection {
    ArrayList,
    MutableMap,
    HashMap
}
import ceylon.json {
    Visitor,
    JsonObject,
    parse,
    visit
}
import ceylon.file {
    File,
    parsePath,
    Directory,
    lines,
    Nil
}

// SUPER LOGGER
Anything(String) log = process.writeLine;
// Anything(String) log = noop;

shared class ClassEmitter(String topLevelClassName) satisfies Visitor {

    class PrintState(shared String file,
        shared StringBuilder builder = StringBuilder(),
        shared variable Boolean omitPrint = false
    ) {}

    value fakePrintState = PrintState{ file = ""; omitPrint = true; };

    ArrayList<PrintState> state = ArrayList<PrintState>{};
    shared MutableMap<String, String> files = HashMap<String, String>{};

    variable Boolean startEntity = true;
    ArrayList<Boolean> level = ArrayList<Boolean>{};

    variable String? currentKey = topLevelClassName;
    String ckey => currentKey else "";
    void clearKey() {
        currentKey = null;
    }

    value isObjectLevel => level.last else true;
    value isArrayLevel => !isObjectLevel;

    variable Integer needToCaptureClasses = 0;
    value isNeedToCapture => needToCaptureClasses > 0;
    void needToCapture() => needToCaptureClasses++;
    void captureClass() => needToCaptureClasses--;


    function makeClazzName(String str)
    => "``str[0..0].uppercased````(str.endsWith("s") then str[1..str.size-2] else str.rest)``";

    function newPrintState(String clazzName) {
        value printState = PrintState(clazzName);
        printState.builder.append("shared class ``clazzName``(");
        return printState;
    }

    void push(Boolean isObject) {

        if(level.empty, state.empty) {
            value clazzName = makeClazzName(ckey);
            log("state [] new printState: ``clazzName``");
            state.add(newPrintState(clazzName));
            level.push(isObject);
            startEntity = true;
            return;
        }

        assert(exists lastLevel = level.last);
        switch([lastLevel, isObject])
        case([true, true]) {
            value clazzName = makeClazzName(ckey);
            log("state [] new printState: ``clazzName``");
            state.add(newPrintState(clazzName));
        }
        case([true, false]) {
            needToCapture();
        }
        case([false, true]) {
            if(isNeedToCapture) {
                value clazzName = makeClazzName(ckey);
                log("state [] new printState: ``clazzName``");
                state.add(newPrintState(clazzName));
            } else {
                state.add(fakePrintState);
            }
        }
        case([false, false]) {
        }
        else {
            "Unbelievable"
            assert(false);
        }
        level.push(isObject);
        startEntity = true;
        log("state [] printState: ``state.size``, level: ``level.size``");
    }

    void pop() {
        assert(exists curLevel = level.last,
               exists printState = state.last);

        value prevLevel = level.exceptLast.last else true;

        switch([prevLevel, curLevel])
        case([true, true]) {
            files.put(printState.file, printState.builder.string);
            state.pop();
        }
        case([true, false]) {
            log("DISABLE OMIT PRINT");
            printState.omitPrint = false;
        }
        case([false, true]) {
            if(isNeedToCapture){
                files.put(printState.file, printState.builder.string);
                captureClass();
                state.pop();
                log("ENABLE OMIT PRINT");
                if(exists printState2 = state.last){
                    printState2.omitPrint = true;
                }
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
        log("state [] printState: ``state.size``, level: ``level.size``");
    }


    void print(String string) {
        if(exists printState = state.last, !printState.omitPrint) {
            log("print >> \"``string``\"");
            printState.builder.append(string);
        }
    }

    void printIndent() => print("    ");

    void printBreakline() => print("\n");

    void printField(String string) {
        if(isArrayLevel) {
            print("{``string``*} ``ckey``");
        }  else  {
            print("``string`` ``ckey``");
        }
    }

    "adds comma separators"
    void printFormat() {
        if(isObjectLevel, startEntity){
            printBreakline();
            printIndent();
            startEntity = false;
        } else if(isArrayLevel, startEntity) {
            startEntity = false;
        } else {
            print(",");
            printBreakline();
            printIndent();
        }
    }

    shared actual void onStartObject(){
        log("event -> onStartObject");
        printFormat();
        printField(makeClazzName(ckey));
        push(true);
        clearKey();
    }

    shared actual void onKey(String key) {
        log("event -> onKey: \"``key``\"");
        currentKey = key;
    }

    shared actual void onEndObject() {
        log("event -> onEndObject");
        printBreakline();
        print(") {}");
        pop();
    }

    shared actual void onStartArray(){
        log("event -> onStartArray");
        printFormat();
        push(false);
    }

    shared actual void onEndArray() {
        log("event -> onEndArray");
        pop();
    }

    shared actual void onString(String s){
        log("event -> onString");
        printFormat();
        printField("String");
        clearKey();
    }

    shared actual void onNumber(Integer|Float n) {
        log("event -> onNumber");
        printFormat();
        printField(if(is Integer n) then "Integer" else "Float");
        clearKey();
    }

    shared actual void onBoolean(Boolean v) {
        log("event -> onBoolean");
        printFormat();
        printField("Boolean");
        clearKey();
    }

    shared actual void onNull() {
        log("event -> onNull");
        printFormat();
        printField("Nothing");
        clearKey();
    }
}

shared void run(){
    String json = """ {
                        "name": "Vitaly",
                        "age": 30,
                        "pets": [
                            {
                             "type" : "dog",
                             "name" : "Baks"
                            },
                            {
                             "type" : "cat",
                             "name" : "Murzik"
                            }
                        ],
                        "adress": {
                            "street" : "Gagarin",
                            "buildNumber": 55
                        }
                     }""";
//    String json = """ {
//                        "name": "Vitaly",
//                        "age": 30
//                     }""";
//    String json = """ {
//                        "pets": [
//                                    {
//                                        "name":"Baks"
//                                    },
//                                    {
//                                        "name":"Baks"
//                                    }
//                                ],
//                        "name": "Peter Parker"
//                     }""";

    assert(is JsonObject obj = parse(json));
    value classEmitter = ClassEmitter("Person");
    visit(obj, classEmitter);
    print(classEmitter.files);
}


shared void cmd() {
    "Class name should be given for the root class: -classname=ClassName"
    assert(exists clazzName = process.namedArgumentValue("classname"));

    "Input file should be given: -inputfile=file.json"
    assert(exists inputFileName = process.namedArgumentValue("inputfile"));

    "Output dir should be given: -outdir=path/to/dir"
    assert(exists outDirName = process.namedArgumentValue("outDir"));

    "Input file should exists: ``inputFileName``"
    assert(is File inputFile = parsePath(inputFileName).resource);

    "Output dir should exists: ``outDirName``"
    assert(is Directory outDir = parsePath(outDirName).resource);

    String fileContent = "\n".join(lines(inputFile));

    assert(is JsonObject obj = parse(fileContent));
    value classEmitter = ClassEmitter(clazzName);
    visit(obj, classEmitter);

    classEmitter.files.each((clazzName -> classContent) {
        if(is Nil outFile = outDir.childResource("``clazzName``.ceylon").linkedResource) {
            outFile.createFile().Overwriter().write(classContent);
            print("File: ``outFile.path`` created!");
        }
    });
//    print(classEmitter.files);
}
