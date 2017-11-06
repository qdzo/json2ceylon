shared String->String emitClass(String->{[String, String]*} classInfo) {
    value b = StringBuilder();
    b.append("serializable");
    b.appendNewline();
    value className->fields = classInfo;
    b.append("shared class ``className``(");
        value indent = "\n    ";
        b.append(indent);
        b.append(",``indent``".join(fields.map(fieldTemplate)));
        b.appendNewline();
        b.append(") {}");
    return className->b.string;
}

// experiments with generating self deserializable class
shared String->String emitExternalizableClass(String->{[String, String]*} classInfo) {
    value b = StringBuilder();
    value className->fields = classInfo;
    b.append("import ceylon.json { parse, JsonObject }");
    b.appendNewline();
    b.appendNewline();
    b.append("shared class ``className``(String|JsonObject json) {");
    value indent = "\n    ";
    b.append(indent);
    b.append("assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parse(json));");
    b.appendNewline();

    for([type, name] in fields) {
        b.append(indent);
        if(type in {"String", "String?", "Integer", "Float", "Boolean"}) {
            b.append("assert(is ``type`` _``name`` = jsObj.get``type.replaceFirst("?", "")``OrNull(\"``name``\");");
        }
        else if(type.contains("["), type.containsAny {"String", "String?", "Integer", "Float", "Boolean"}) {
            b.append("assert(is ``type``* _``name`` = jsObj.getArray((\"``name``\").narrow<``type``>().sequence();");
        }
        else if(type.contains("[")) {
            b.append("assert(is [JsonObject*] _``name`` = jsObj.getArray((\"``name``\").narrow<JsonObject>().sequence();");
        }
        else {
            b.append("assert(is JsonObject _``name`` = jsObj.getObject((\"``name``\");");
        }
    }

    b.appendNewline();
    for([type, name] in fields) {
        b.append(indent);
        if(type in {"String", "String?", "Integer", "Float", "Boolean"}) {
            b.append("shared ``type`` ``name`` => _``name``;");
        }
        else if(type.contains("["), type.containsAny {"String", "String?", "Integer", "Float", "Boolean"}) {
            b.append("shared ``type`` ``name`` => _``name``;");
        }
        else if(type.contains("[")) {
            b.append("shared ``type`` ``name`` => _``name``.collect(``type[1..type.size-3]``);");
        }
        else {
            b.append("shared ``type`` ``name`` => ``type``(_``name``);");
        }
    }
    b.appendNewline();
    b.append("}");
    return className->b.string;
}


