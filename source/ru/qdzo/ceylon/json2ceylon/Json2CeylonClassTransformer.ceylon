import ceylon.json {
    JsonObject,
    JsonArray,
    JsonValue=Value
}

import ru.qdzo.ceylon.json2ceylon {
    formatClassName
}
import ceylon.time.iso8601 {
    parseDate,
    parseDateTime,
    parseTime
}
import ceylon.time {
    Date,
    DateTime,
    Time
}
import java.util {
    UUID
}
import java.lang {
    IllegalArgumentException
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

    <String->{[String,String]*}> classInfoToEntry(ClassInfo ci) => ci.name -> ci.fields;

    shared {<String->{[String,String]*}>*} result
            => collectClass(jsObj, ClassInfo(topLevelClassName)).map(classInfoToEntry);

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
        case (is String) {
            String guessedType = guessStringContentType(val);
            classInfo.addField(formatArrayNesting(guessedType, inDepth), fieldName); }
        case (is Boolean) { classInfo.addField(formatArrayNesting("Boolean", inDepth), fieldName); }
        case (is Integer) { classInfo.addField(formatArrayNesting("Integer", inDepth), fieldName); }
        case (is Float) { classInfo.addField(formatArrayNesting("Float", inDepth), fieldName); }
        case (is Null) { classInfo.addField(formatArrayNesting("Anything", inDepth), fieldName); }
        return [];
    }
}

String guessStringContentType(String val){
    try {
        if(parseDateTime(val) is DateTime) {
            return "DateTime";
        }
        if(parseDate(val) is Date) {
            return "Date";
        }
        if(parseTime(val) is Time) {
            return "Time";
        }
        UUID.fromString(val);
        return "UUID";
    } catch (IllegalArgumentException e) {
        return "String";
    }
}
