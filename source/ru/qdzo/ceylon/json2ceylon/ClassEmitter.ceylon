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

shared class ClassEmitter(String topLevelClassName) satisfies Visitor {

    class PrintState(shared String file, shared StringBuilder builder, shared variable Boolean ommitPrint) {}
    ArrayList<PrintState> state = ArrayList<PrintState>{};
    shared MutableMap<String, String> files = HashMap<String, String>{};

    variable Boolean entityStart = true;
    ArrayList<Boolean> inObject = ArrayList<Boolean>{};
    variable Integer arrayDepth = 0;
    variable Integer classCapturedInArray = 0;
    variable String? currentKey = topLevelClassName;

    value isInObject => inObject.last else true;
    value isInArray => !isInObject;
    value isObjectInArray => (inObject.size > 1) then !(inObject.exceptLast.last else true) else false;
    value isObjectNotCaptured => arrayDepth > classCapturedInArray;
    void captureObject() => classCapturedInArray++;
    String ckey => currentKey else "";

    void clearKey() {
       currentKey = null;
    }

    function capitalize(String str) => "``str[0..0].uppercased````str.rest``";
    function makeClazzName(String str) => "``str[0..0].uppercased````(str.endsWith("s") then str[1..str.size-2] else str.rest)``";
    function decapitalize(String str) => "``str[0..0].lowercased````str.rest``";

    function newFile(String clazzName) {
        value printState = PrintState(clazzName, StringBuilder(), false);
        printState.builder.append("shared class ``clazzName``(");
        return printState;
    }

    // SUPER LOGGER
    value log = process.writeLine;

    void push(Boolean isObject) {
        if(!isObjectNotCaptured, isObjectInArray) {
            return;
        }
        if(isObject) {
            value clazzName = makeClazzName(ckey);
            log("state [] new printState: ``clazzName``");
            state.add(newFile(clazzName));
            entityStart = true;
        } else {
            arrayDepth++;
        }
        inObject.push(isObject);
        entityStart = true;
        log("state [] printState: ``state.size``, inObject: ``inObject.size``");
    }

    void pop() {
        if(!isObjectNotCaptured, isObjectInArray) {
            return;
        }
        if(exists isObject = inObject.pop(),
            exists printState = state.last) {
            if(isObject) {
                files.put(printState.file, printState.builder.string);
                state.pop();
                if(isObjectNotCaptured){
                    log("ENABLE OMIT PRINT");
                    if(exists printState2 = state.last){
                        printState2.ommitPrint = true;
                    }
                    captureObject();
                }
            } else {
                arrayDepth--;
                classCapturedInArray--;
                log("DISABLE OMIT PRINT");
                printState.ommitPrint = false;
            }
        }
        log("state [] printState: ``state.size``, inObject: ``inObject.size``");
    }


    void print(String string) {
        if(exists printState = state.last,
            !printState.ommitPrint) {
            log("print >> \"``string``\"");//, isCurrentInArray=``isObjectInArray``, arrayDepth=``arrayDepth``, classCapturedInArray=``classCapturedInArray``");
        printState.builder.append(string);
    }
}

    void printIndent() => print("    ");

    void printBreakline() => print("\n");

    void printField(String string) {
        if(isInArray) {
            print("{``string``*} ``ckey``");
        }  else  {
            print("``string`` ``ckey``");
        }
    }


    "adds comma separators"
    void printFormat() {
        if(isInObject, entityStart){
            printBreakline();
            printIndent();
            entityStart = false;
        } else if(isInArray, entityStart) {
            entityStart = false;
        } else {
            print(",");
            printBreakline();
            printIndent();
        }
    }

    shared actual void onStartObject(){
        log("event -> onStartObject");
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
        // variable Boolean captured = false;
        // if(!isObjectInArray) {
        //     pop();
        // }
        // if(isObjectInArray, isObjectNotCaptured) {
        //     classCapturedInArray++;
        //     captured = true;
        //     pop();
        // }
        // if(captured, exists printState = state.last) {
        //     log("ENABLE OMIT PRINT");
        //     printState.ommitPrint = true;
        // }
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
                        ]
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

