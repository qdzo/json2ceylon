import ceylon.json {
    JsonObject,
    JsonArray,
    JsonValue=Value
}

import ru.qdzo.ceylon.json2ceylon {
    formatClassName
}

shared class Json2CeylonClassTransformer(JsonObject jsObj, String topLevelClassName) {

    shared class ClassInfo(shared String name)  {
        variable [[String, String]*] _fields = [];
        shared  [[String, String]*] fields => _fields;

        shared void addField(String fieldType, String fieldName) {
            _fields = _fields.append([[fieldType, fieldName]]);
        }
        string => "{ ``name``: ``fields`` }";
    }

    <String->{[String,String]*}> classInfoToEntrie(ClassInfo ci) => ci.name -> ci.fields;

    shared {<String->{[String,String]*}>*} result
            => collectClass(jsObj, ClassInfo(topLevelClassName)).map(classInfoToEntrie);

    [ClassInfo*] collectClass(JsonObject jsObj, ClassInfo classInfo) {
        variable [ClassInfo*] collectors = [classInfo];
        for (key->val in jsObj) {
            collectors = collectors.append(collectVal(val, classInfo, key));
        }
        return collectors;
    }

    [ClassInfo*] collectVal(JsonValue val, ClassInfo classInfo, String fieldName, Integer inDepth = 0) {
        switch (val)
        case (is JsonObject) {
            value className = formatClassName(fieldName);
            classInfo.addField(formatArrayNesting(className, inDepth), fieldName);
            return collectClass(val, ClassInfo(className));
        }
        case (is JsonArray) { return collectVal (val.first, classInfo, fieldName, inDepth + 1); }
        case (is String) { classInfo.addField(formatArrayNesting("String", inDepth), fieldName); }
        case (is Boolean) { classInfo.addField(formatArrayNesting("Boolean", inDepth), fieldName); }
        case (is Integer) { classInfo.addField(formatArrayNesting("Integer", inDepth), fieldName); }
        case (is Float) { classInfo.addField(formatArrayNesting("Float", inDepth), fieldName); }
        case (is Null) { classInfo.addField(formatArrayNesting("Anything", inDepth), fieldName); }
        return [];
    }
}

