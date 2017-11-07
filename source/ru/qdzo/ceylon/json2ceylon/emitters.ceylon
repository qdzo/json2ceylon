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
    b.append("import ceylon.json { parse, JsonObject, JsonArray }");
    b.appendNewline();
    b.appendNewline();
    b.append("shared class ``className``(String|JsonObject json) {");
    value indent = "\n    ";
    b.append(indent);
    b.append("assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parse(json));");
    b.appendNewline();

    for([type, name] in fields) {
        b.append(indent);
        switch(describeType(type))
        case(basic) {
            b.append("assert(is ``type`` _``name`` = jsObj.get``type``OrNull(\"``name``\"));");
        }
        case(basicOptional) {
            b.append("``type`` _``name`` = jsObj.get``type.replaceFirst("?", "")``OrNull(\"``name``\");");
        }
        case(sequenceWithBasic) {
            b.append("assert(is ``type`` _``name`` = jsObj.getArray(\"``name``\").narrow<``type[1..type.size-3]``>());");
        }
        case(sequenceWithComplex) {
            b.append("assert(is [JsonObject*] _``name`` = jsObj.getArray(\"``name``\").narrow<JsonObject>());");
        }
        case(complex) {
            b.append("assert(is JsonObject _``name`` = jsObj.getObject(\"``name``\"));");
        }
    }

    b.appendNewline();
    for([type, name] in fields) {
        b.append(indent);
        switch(describeType(type))
        case (basic|basicOptional) {
            b.append("shared ``type`` ``name`` => _``name``;");
        }
        case (sequenceWithBasic) {
            b.append("shared ``type`` ``name`` => _``name``;");
        }
        case(sequenceWithComplex) {
            b.append("shared ``type`` ``name`` => _``name``.collect(``type[1..type.size-3]``);");
        }
        case(complex) {
            b.append("shared ``type`` ``name`` => ``type``(_``name``);");
        }
    }
    b.appendNewline();

    b.append(indent);
    b.append("shared JsonObject toJson => JsonObject {");
    b.append(indent);
    b.append("    ");
    assert(exists [ftype, fname] = fields.first);
    b.append(fieldToJsonEntry(ftype, fname));
    for([type, name] in fields.rest) {
        b.append(",");
        b.append(indent);
        b.append("    ");
        b.append(fieldToJsonEntry(type, name));
    }
    b.append(indent);
    b.append("};");
    b.appendNewline();
    b.append("}");
    return className->b.string;
}

String fieldToJsonEntry(String type,String name) {
    if(type in {"String", "String?", "Integer", "Float", "Boolean"}) {
        return "\"``name``\" -> ``name``";
    }
    else if(type.contains("["), type.containsAny {"String", "String?", "Integer", "Float", "Boolean"}) {
        return "\"``name``\" -> JsonArray(``name``)";
    }
    else if(type.contains("[")) {
        return "\"``name``\" -> JsonArray(``name``*.toJson)";
    }
    else {
        return "\"``name``\" -> ``name``.toJson";
    }
}

shared abstract class Type() of basic|complex|basicOptional|sequenceWithBasic|sequenceWithComplex {}

shared object basic extends Type() {}
shared object complex extends Type() {}
shared object basicOptional extends Type() {}
shared object sequenceWithBasic extends Type() {}
shared object sequenceWithComplex  extends Type() {}

Type describeType(String t) {
    if(t in {"String", "Integer", "Float", "Boolean"}) {
        return basic;
    }
    else if(t == "String?") {
        return basicOptional;
    }
    else if(t.contains("["), t.containsAny {"String", "String?", "Integer", "Float", "Boolean"}) {
        return sequenceWithBasic;
    }
    else if(t.contains("[")) {
        return sequenceWithComplex;
    }
    else {
        return complex;
    }
  }
