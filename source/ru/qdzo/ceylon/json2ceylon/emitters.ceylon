shared String->String emitClass(String->{[String, String]*} classInfo) {
    value className->fields = classInfo;
    value uniqTypes = set(fields.map(([t, v]) => t));
    value classContent =
            "``emitAdditionalImports(uniqTypes)``

             serializable
             shared class ``className``(
                 ``",\n    ".join(fields.map(sharedFieldTemplate))``
             ) {}";
    return className->classContent;
//    value b = StringBuilder();
//    b.append("serializable");
//    b.appendNewline();
//    b.append("shared class ``className``(");
//    value indent = "\n    ";
//    b.append(indent);
//    b.append(",``indent``".join(fields.map(sharedFieldTemplate)));
//    b.appendNewline();
//    b.append(") {}");
//    return className->b.string;
}

Map<String,[String[2]*]> imports = map {
    "Time"->[["ceylon.time", "Time"],
             ["ceylon.time.iso8601", "parseTime"]],
    "Date"->[["ceylon.time", "Date"],
             ["ceylon.time.iso8601", "parseDate"]],
    "DateTime"->[["ceylon.time", "DateTime"],
                 ["ceylon.time.iso8601", "parseDateTime"]],
    "UUID"->[["java.util", "UUID"]]
};

String emitAdditionalImports(Set<String> types){
    value requiredImports = imports.filterKeys((key) => key in types);
    if(requiredImports.keys.size > 0) {
        value mergedImports = mergeImports(requiredImports);
        value b = StringBuilder();
        for (pkg->classesOrFns in mergedImports) {
             b.append("import ``pkg`` {
                           ``"\n    ".join(classesOrFns)``
                       }\n");
        }
        return b.string;
    }
    return "";
}

Map<String, [String*]> mergeImports({<String->[String[2]*]>*} imports) {
    return imports
        .flatMap((className->importPaths)=>importPaths)
        .group(([pkg, _])=> pkg)
        .mapItems((String key, [String[2]+] paths) => paths.collect(([pkg, classOrFn]) => classOrFn));
}



// experiments with generating self deserializable class
shared String->String emitExternalizableClass(String->{[String, String]*} classInfo) {
    value b = StringBuilder();
    value className->fields = classInfo;
    value n = "import ceylon.json { parse, JsonObject, JsonArray }

               shared class ``className`` {
                   ``";\n    ".join(fields.map(sharedFieldTemplate))``;

                   shared new (
                           ``",\n            ".join(fields.map(fieldTemplate))``) {
                       ``";\n        ".join(fields.map((f) => "this.``f[1]`` = ``f[1]``"))``;
                   }

                   shared new fromJson(String|JsonObject json) {
                       assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parse(json));
                       ``",\n            "``
                   }

                }";
//    b.append("import ceylon.json { parse, JsonObject, JsonArray }");
//    b.appendNewline();
//    b.appendNewline();
//    b.append("shared class ``className`` {");
//    value indent = "\n    ";
//    value indent2 = "\n        ";
//    value indent3 = "\n            ";
//    b.appendNewline();
//    b.append(indent);
//     fields
//    b.append(";``indent``".join(fields.map(sharedFieldTemplate)));
//    b.append(";");
//    b.appendNewline();
    // base constructor
//    b.append(indent);
//    b.append("shared new(");
//    b.append(indent3);
//    b.append(",``indent3``".join(fields.map(fieldTemplate)));
//    b.append(") {");
//    b.appendNewline();
//    b.append(indent2);
//    b.append(";``indent2``".join(fields.map((f) => "this.``f[1]`` = ``f[1]``")));
//    b.append(";");
//    b.append(indent);
//    b.append("}");
//    b.appendNewline();
//    b.append(indent);
    // fromJson constructor
//    b.append("shared new fromJson(String|JsonObject json) {");
//    b.appendNewline();
//    b.append(indent2);
//    b.append("assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parse(json));");
//    b.appendNewline();
// TODO Replace next lines with new code
//    for([type, name] in fields) {
//        b.append(indent2);
//        switch(describeType(type))
//        case(basic) {
//            b.append("assert(is ``type`` ``name`` = jsObj.get(\"``name``\"));");
//        }
//        case(basicOptional) {
//            b.append("assert(is ``type`` ``name`` = jsObj.get(\"``name``\"));");
//        }
//        case(sequenceWithBasic) {
//            b.append("assert(is ``type`` ``name`` = jsObj.getArray(\"``name``\").narrow<``type[1..type.size-3]``>());");
//        }
//        case(sequenceWithComplex) {
//            b.append("assert(is [JsonObject*] ``name`` = jsObj.getArray(\"``name``\").narrow<JsonObject>().sequence());");
//        }
//        case(complex) {
//            b.append("assert(is JsonObject ``name`` = jsObj.get(\"``name``\"));");
//        }
//    }
//    b.appendNewline();
//    for([type, name] in fields) {
//        b.append(indent2);
//        switch(describeType(type))
//        case (basic|basicOptional) {
//            b.append("this.``name`` = ``name``;");
//        }
//        case (sequenceWithBasic) {
//            b.append("this.``name`` = ``name``;");
//        }
//        case(sequenceWithComplex) {
//            b.append("this.``name`` = ``name``.collect(``type[1..type.size-3]``.fromJson);");
//        }
//        case(complex) {
//            b.append("this.``name`` = ``type``.fromJson(``name``);");
//        }
//    }
//    b.append(indent);
//    b.append("}");
//    b.appendNewline();
//    b.append(indent);
//    b.append("shared JsonObject toJson => JsonObject {");
//    b.append(indent2);
//    assert(exists [ftype, fname] = fields.first);
//    b.append(fieldToJsonEntry(ftype, fname));
//    for([type, name] in fields.rest) {
//        b.append(",");
//        b.append(indent2);
//        b.append(fieldToJsonEntry(type, name));
//    }
//    b.append(indent);
//    b.append("};");
//    b.appendNewline();
//    b.append("}");
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

String assertFields({String[2]*} fields)
        => "\n    ".join(fields.map((field) => assertField(*field)));

String assertField(String type, String name) => switch(describeType(type))
        case(basic) "assert(is ``type`` ``name`` = jsObj.get(\"``name``\"));"
        case(basicOptional) "assert(is ``type`` ``name`` = jsObj.get(\"``name``\"));"
        case(sequenceWithBasic) "assert(is ``type`` ``name`` = jsObj.getArray(\"``name``\").narrow<``type[1..type.size-3]``>());"
        case(sequenceWithComplex) "assert(is [JsonObject*] ``name`` = jsObj.getArray(\"``name``\").narrow<JsonObject>().sequence());"
        case(complex) "assert(is JsonObject ``name`` = jsObj.get(\"``name``\"));";

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
