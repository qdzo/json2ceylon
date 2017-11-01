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

    variable Boolean objectOrArrayStart = true;
    ArrayList<Boolean> inObject = ArrayList<Boolean>{};
    variable Integer arrayDepth = 0;
    variable Integer classCapturedInArray = 0;
    variable String? currentKey = topLevelClassName;

    value isInObject => inObject.last else true;
    value isInArray => !isInObject;
    value isCurrentInArray => (inObject.size > 1) then !(inObject.exceptLast.last else true) else false;
    value isObjectNotCaptured => arrayDepth > classCapturedInArray;
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
        if(isObject) {
            value clazzName = makeClazzName(currentKey else "");
            log("state <> new printState: ``clazzName``");
            state.add(newFile(clazzName));
            objectOrArrayStart = true;
        }
        inObject.push(isObject);
        log("state <>  printState: ``state.size``, inObject: ``inObject.size``");
    }

    void pop() {
        if(exists isObject = inObject.pop(),
            isObject,
            exists printState = state.pop()){
            files.put(printState.file, printState.builder.string);
        }
        log("state ->  printState: ``state.size``, inObject: ``inObject.size``");
    }


    void print(String string) {
        if(exists printState = state.last,
            !printState.ommitPrint) {
            log("print >> \"``string``\"");//, isCurrentInArray=``isCurrentInArray``, arrayDepth=``arrayDepth``, classCapturedInArray=``classCapturedInArray``");
        printState.builder.append(string);
    }
    //        if((isCurrentInArray && arrayDepth > classCapturedInArray)
        //        || (!isCurrentInArray && arrayDepth == classCapturedInArray)) {
        //
        //            log("string=``string``, isCurrentInArray=``isCurrentInArray``, arrayDepth=``arrayDepth``, classCapturedInArray=``classCapturedInArray``");
        //        }
}

    void indent() => print("    ");
//    void printArrayValue(String string) => print("{``string``*} ``ckey``");

    void printBreakline() => print("\n");
    void printField(String string) {
        if(isInArray) {
            print("{``string``*} ``ckey``");
        }  else  {
            print("``string`` ``ckey``");
        }
    }


    "adds comma separators"
    void emitValue() {
        if(isInObject, objectOrArrayStart){
            printBreakline();
            indent();
            objectOrArrayStart = false;
        } else if(isInArray, objectOrArrayStart) {
            objectOrArrayStart = false;
        } else {
            print(",");
            printBreakline();
            indent();
        }
    }

    "Prints an `Object`"
    shared actual void onStartObject(){
        log("event -> onStartObject");
//        emitValue();
        if(exists ck = currentKey) {
            if(isInObject) {
                printField(makeClazzName(ck));
                push { isObject = true; };
            } else if(isObjectNotCaptured) {
                printField(makeClazzName(ck));
                push { isObject = true; };
            }
            currentKey = null;
        }
    }

    shared actual void onKey(String key) {
        log("event -> onKey: \"``key``\"");
        currentKey = key;
    }

    shared actual void onEndObject() {
        log("event -> onEndObject");
        printBreakline();
        print(") {}");
        variable Boolean captured = false;
        if(!isCurrentInArray) {
            pop();
        }
        if(isCurrentInArray, isObjectNotCaptured) {
            classCapturedInArray++;
            captured = true;
            pop();
        }
        if(captured, exists printState = state.last) {
            log("ENABLE OMIT PRINT");
            printState.ommitPrint = true;
        }
    }

    shared actual void onStartArray(){
        log("event -> onStartArray");
        emitValue();
        objectOrArrayStart = true;
        push { isObject = false; };
        arrayDepth++;
    }

    shared actual void onEndArray() {
        log("event -> onEndArray");
        arrayDepth--;
        classCapturedInArray--;
        pop();
        if(exists printState = state.last) {
            log("DISABLE OMIT PRINT");
            printState.ommitPrint = false;
        }
    }

    shared actual void onString(String s){
        log("event -> onString");
        emitValue();
        printField("String");
        clearKey();
    }

    shared actual void onNumber(Integer|Float n) {
        log("event -> onNumber");
        emitValue();
        printField(if(is Integer n) then "Integer" else "Float");
        clearKey();
    }

    shared actual void onBoolean(Boolean v) {
        log("event -> onBoolean");
        emitValue();
        printField("Boolean");
        clearKey();
    }

    shared actual void onNull() {
        log("event -> onNull");
        emitValue();
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

