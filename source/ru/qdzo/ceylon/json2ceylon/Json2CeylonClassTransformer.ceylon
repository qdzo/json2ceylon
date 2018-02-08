import ceylon.collection {
    ArrayList
}
import ceylon.file {
    parsePath,
    File,
    lines
}
import ceylon.json {
    Visitor,
    JsonObject,
    JsonArray,
    JsonValue=Value,
    parse
}

shared class Json2CeylonClassTransformer(String topLevelClassName) satisfies Visitor {

    class ClassInfoCollecttor(className) {
        variable {[String,String]*} _fields = {};
        variable Boolean enabled = true;
        shared String className;
        shared {[String,String]*} fields => _fields;
        shared void disable() {
            log("DISABLE ADDING for ``className``");
            enabled = false;
        }
        shared void enable() {
            log("ENABLE ADDING for ``className``");
            enabled = true;
        }
        shared default void add(String[2] field){
            if(enabled) {
                log("Add field: ``field`` for class ``className``");
                _fields = _fields.chain { field };
            }
        }
    }

    object fakeInfoCollector extends ClassInfoCollecttor(""){
        shared actual void add(String[2] field) => log("Fake add: ``field``");
    }

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
    void needToCapture() {
        log("state [] need to capture value from array");
        needToCaptureValues++;
    }
    void captureVal() {
        log("state [] val captured from array");
        needToCaptureValues--;
    }

    void push(Boolean isObject) {
        if(level.empty, state.empty) {
            value clazzName = formatClazzName(ckey);
            log("state [] new classCollector: ``clazzName``");
            state.add(ClassInfoCollecttor(clazzName));
            level.push(isObject);
            return;
        }

        assert(exists lastLevel = level.last);
        switch([lastLevel, isObject])
        case([true, true]) {
            value clazzName = formatClazzName(ckey);
            log("state [] new classCollector: ``clazzName``");
            state.add(ClassInfoCollecttor(clazzName));
        }
        case([true, false]) {
            needToCapture();
        }
        case([false, true]) {
            if(isNeedToCapture) {
                value clazzName = formatClazzName(ckey);
                log("state [] new classCollector: ``clazzName``");
                state.add(ClassInfoCollecttor(clazzName));
            } else {
                log("state [] fakeCollector");
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
            _result = _result.chain {
                classCollector.className->classCollector.fields
            };
            state.pop();
        }
        case([true, false]) {
            if(!isNeedToCapture) {
                state.last?.enable();
            }
        }
        case([false, true]) {
            if(isNeedToCapture){
                _result = _result.chain {
                    classCollector.className->classCollector.fields
                };
                captureVal();
                state.pop();
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


    void performAddField(String fieldType, String field)
            => state.last?.add([fieldType, field]);

    void addField(String fieldType) {
        value clazz = formatClazzName(fieldType);
        value field = formatFieldName(ckey);
        if(isArrayLevel) {
            performAddField("[``clazz``*]", field);
        }  else  {
            performAddField(clazz, field);
        }
        if(isArrayLevel,
            isNeedToCapture,
            fieldType != ckey) { // if fieldType is not new Class
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


shared class Json2CeylonClassTransformer2(JsonObject jsObj, String topLevelClassName) {

    shared class ClassInfo(shared String name)  {
        variable [[String, String]*] _fields = [];

        shared  [[String, String]*] fields => _fields;

        shared ClassInfo addField(String fieldType, String fieldName) {
            _fields = _fields.append([[fieldType, fieldName]]);
            return this;
        }

        string => "{ ``name``: ``fields`` }";
    }

    [ClassInfo*] collectVal(JsonValue val, ClassInfo classInfo, String fieldName, Integer inDepth = 0) {
        switch (val)
        case (is JsonObject) {
            value clazzName = formatClazzName(fieldName);
            classInfo.addField(nestingDepth(clazzName, inDepth), fieldName);
            return collectClass(val, ClassInfo(clazzName));
        }
        case (is JsonArray) {
                return collectVal (val.first, classInfo, fieldName, inDepth + 1);
        }
        case (is String) {
            classInfo.addField(nestingDepth("String", inDepth), fieldName);
            return [];
        }
        case (is Boolean) {
            classInfo.addField(nestingDepth("Boolean", inDepth), fieldName);
            return [];
        }
        case (is Integer) {
            classInfo.addField(nestingDepth("Integer", inDepth), fieldName);
            return [];
        }
        case (is Float) {
            classInfo.addField(nestingDepth("Float", inDepth), fieldName);
            return [];
        }
        case (is Null) {
            classInfo.addField(nestingDepth("Anything", inDepth), fieldName);
            return [];
        }
    }

    String nestingDepth(String typeName, Integer arrayDepth) {
        return "[".repeat(arrayDepth) + typeName + "*]".repeat(arrayDepth);
    }
    [ClassInfo*] collectClass(JsonObject jsObj, ClassInfo classInfo) {
        variable [ClassInfo*] collectors = [classInfo];
        for (key->val in jsObj) {
            collectors = collectors.append(collectVal(val, classInfo, key));
        }
        return collectors;
    }

    shared [ClassInfo*] apply() {
        return collectClass(jsObj, ClassInfo(topLevelClassName));
    }

}


shared void testFN() {
    assert(is File f = parsePath("/home/vbanchenko/Devel/backend/autodelivery-scale-gateway/calc-result.json").resource);
    value content = "".join(lines(f));
    assert(is JsonObject jsObj = parse(content));
    value t = Json2CeylonClassTransformer2(jsObj, "Calc");
    t.apply().each(print);
}
