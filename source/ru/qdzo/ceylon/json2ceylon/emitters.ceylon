shared String->String emitClass(String->{[String, String]*} classInfo) {
    value b = StringBuilder();
    b.append("serializable");
    b.appendNewline();
    value className->fields = classInfo;
    b.append("shared class ``className``(");
        value indent = "\n    ";
        b.append(indent);
        b.append(",``indent``".join(fields.map(sharedFieldTemplate)));
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
    b.append("shared class ``className`` {");
    value indent = "\n    ";
    value indent2 = "\n        ";
    value indent3 = "\n            ";
    b.appendNewline();
    b.append(indent);
    // fields 
    b.append(";``indent``".join(fields.map(sharedFieldTemplate)));
    b.append(";");
    b.appendNewline();
    // base constructor
    b.append(indent);
    b.append("shared new(");
    b.append(indent3);
    b.append(",``indent3``".join(fields.map(fieldTemplate)));
    b.append(") {");
    b.appendNewline();
    b.append(indent2);
    b.append(";``indent2``".join(fields.map((f) => "this.``f[1]`` = ``f[1]``")));
    b.append(";");
    b.append(indent);
    b.append("}");
    b.appendNewline();
    b.append(indent);
    // fromJson constructor
    b.append("shared new fromJson(String|JsonObject json) {");
    b.appendNewline();
    b.append(indent2);
    b.append("assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parse(json));");
    b.appendNewline();

    for([type, name] in fields) {
        b.append(indent2);
        switch(describeType(type))
        case(basic) {
            b.append("assert(is ``type`` ``name`` = jsObj.get``type``OrNull(\"``name``\"));");
        }
        case(basicOptional) {
            b.append("``type`` ``name`` = jsObj.get``type.replaceFirst("?", "")``OrNull(\"``name``\");");
        }
        case(sequenceWithBasic) {
            b.append("assert(is ``type`` ``name`` = jsObj.getArray(\"``name``\").narrow<``type[1..type.size-3]``>());");
        }
        case(sequenceWithComplex) {
            b.append("assert(is [JsonObject*] ``name`` = jsObj.getArray(\"``name``\").narrow<JsonObject>().sequence());");
        }
        case(complex) {
            b.append("assert(is JsonObject ``name`` = jsObj.getObjectOrNull(\"``name``\"));");
        }
    }
    b.appendNewline();
    for([type, name] in fields) {
        b.append(indent2);
        switch(describeType(type))
        case (basic|basicOptional) {
            b.append("this.``name`` = ``name``;");
        }
        case (sequenceWithBasic) {
            b.append("this.``name`` = ``name``;");
        }
        case(sequenceWithComplex) {
            b.append("this.``name`` = ``name``.collect(``type[1..type.size-3]``.fromJson);");
        }
        case(complex) {
            b.append("this.``name`` = ``type``.fromJson(``name``);");
        }
    }
    b.append(indent);
    b.append("}");
    b.appendNewline();
    b.append(indent);
    b.append("shared JsonObject toJson => JsonObject {");
    b.append(indent2);
    assert(exists [ftype, fname] = fields.first);
    b.append(fieldToJsonEntry(ftype, fname));
    for([type, name] in fields.rest) {
        b.append(",");
        b.append(indent2);
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
