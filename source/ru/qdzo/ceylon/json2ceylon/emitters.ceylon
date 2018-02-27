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
}

Map<String,String[2]> imports = map {
    "Time"->["ceylon.time", "Time"],
    "parseTime" -> ["ceylon.time.iso8601", "parseTime"],
    "Date"->["ceylon.time", "Date"],
    "parseDate"-> ["ceylon.time.iso8601", "parseDate"],
    "DateTime"->["ceylon.time", "DateTime"],
    "parseDateTime" ->["ceylon.time.iso8601", "parseDateTime"],
    "UUID"->["java.util", "UUID"],
    "parseJson"-> ["ceylon.json","parseJson = parse"],
    "JsonObject"-> ["ceylon.json","JsonObject"],
    "JsonArray"-> ["ceylon.json","JsonArray"]
};

String emitAdditionalImports(Set<String> types){
    value requiredImports = imports.filterKeys((key) => key in types);
    if(requiredImports.keys.size > 0) {
        value mergedImports = mergeImports(requiredImports);
        value b = StringBuilder();
        for (pkg->classesOrFns in mergedImports) {
             b.append("import ``pkg`` {
                           ``",\n    ".join(classesOrFns)``
                       }\n");
        }
        return b.string;
    }
    return "";
}

// Map of packageName->[importEntities]
Map<String, [String*]> mergeImports({<String->String[2]>*} imports) {
    return imports
        .map((className->importPaths)=>importPaths)
        .group(([pkg, _])=> pkg)
        .mapItems((String key, [String[2]+] paths) => paths.collect(([pkg, classOrFn]) => classOrFn));
}

Set<String> findAdditionalJsonTypesForImport(Set<String> types){
    Boolean isArrayNeeded = types.find {
        Boolean selecting(String t) {
            return sequenceWithBasic.exactly(t) ||
            sequenceWithAnything.exactly(t) ||
            sequenceWithComplex.exactly(t) ||
            sequenceWithStringParsed.exactly(t);
        }
    } exists;
    if(isArrayNeeded) {
        return types.union(set{"parseJson", "JsonObject", "JsonArray"});
    }
    return types.union(set{"parseJson", "JsonObject"});
}

// experiments with generating self deserializable class

shared String->String emitExternalizableClass(String->{[String, String]*} classInfo) {
    value className->fields = classInfo;
    value uniqTypes = set(fields.map(([t, v]) => t));
    value classContent
             = "shared class ``className`` {
                    ``defineFields(fields, 1)``;

                    shared new (
                            ``defineConstructorProps(fields, 3)``) {

                        ``assignFields(fields, 2)``;
                    }

                    shared new fromJson(String|JsonObject json) {
                        assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parseJson(json));
                        ``assertFields(fields, 2)``

                        ``assignFields(fields, 2)``
                    }

                    ``uniqTypes.contains("UUID") then defineParseUUIDFn() else ""``

                    shared JsonObject toJson => JsonObject {
                        ``fieldsToJsonEntries(fields, 2)``
                    }

                }";
value importLines = emitAdditionalImports(findAdditionalJsonTypesForImport(uniqTypes));
    return className-> importLines + "\n\n" + classContent;
}

String defineParseUUIDFn() => "UUID(String) parseUUID = UUID.fromString;";

String defineFields({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize),
            semicolonWithIndent = ";" + indent)
            semicolonWithIndent.join(fields.map(sharedFieldTemplate));

String defineConstructorProps({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize),
               commaWithIndent = "," + indent)
               commaWithIndent.join(fields.map(fieldTemplate));

String fieldsToJsonEntries({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize),
               commaWithIndent = "," + indent)
               commaWithIndent.join(fields.map((field) => fieldToJsonEntry(*field)));

String fieldToJsonEntry(String type, String name)
        => switch (describeType(type))
           case (basic) "\"``name``\" -> ``name``"
           case (complex) "\"``name``\" -> ``name``.toJson"
           case (anything) "\"``name``\" -> ``name``"
           case (stringParsed) "\"``name``\" -> ``name``.string"
           case (sequenceWithBasic) "\"``name``\" -> JsonArray(``name``)"
           case (sequenceWithAnything) "\"``name``\" -> JsonArray(``name``)"
           case (sequenceWithComplex) "\"``name``\" -> JsonArray(``name``*.toJson)"
           case (sequenceWithStringParsed) "\"``name``\" -> JsonArray(``name``*.string)";

String assertFields({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize))
           indent.join(fields.map((field) => assertField(*field)));

String assertField(String type, String name) => switch(describeType(type))
        case(basic) "assert(is ``type`` ``name`` = jsObj.get(\"``name``\"));"
        case(anything) "assert(is ``type`` ``name`` = jsObj.get(\"``name``\"));"
        case(complex) "assert(is JsonObject ``name``JsObj = jsObj.get(\"``name``\"),
                              is ``type`` ``name`` = ``type``.fromJson(``name``JsObj));"
        case(stringParsed) "assert(is String ``name``Str = jsObj.get(\"``name``\"),
                                   is ``type`` ``name`` = parse``type``(``name``Str));"
        case(sequenceWithBasic) "assert(is ``type`` ``name`` = jsObj.getArray(\"``name``\").narrow<``type[1..type.size-3]``>());" // BUG: supports only one nesting level
        case(sequenceWithComplex) "assert(is [JsonObject*] ``name``jsObjs = jsObj.getArray(\"``name``\").narrow<JsonObject>().sequence(),
                                          is [``type``*] ``name`` = ``name``JsObjs.collect(``type``.fromJson));"
        case(sequenceWithAnything) "assert(is [Anything*] ``name`` = jsObj.getArray(\"``name``\").sequence());"
        case(sequenceWithStringParsed) "assert(is [String*] ``name``Strs = jsObj.getArray(\"``name``\").narrow<String>().sequence(),
                                               is [``type``*] ``name`` = ``name``Strs.map(parse``type``).narrow<``type``>().sequence());";

String assignFields({String[2]*} fields, Integer indentSize)
=> let(indent = makeIndentWithNewLine(indentSize))
       indent.join(fields.map(([_,name]) => "this.``name`` = ``name``;"));

shared abstract class Type() of basic|complex|anything|stringParsed|sequenceWithBasic|sequenceWithAnything|sequenceWithComplex|sequenceWithStringParsed {
    shared formal Boolean exactly(String str);
    shared formal {String*} enum;
}

Type describeType(String str) {
    assert(exists t = `Type`.caseValues.find((t)=> t.exactly(str)));
    return t;
}

shared object basic extends Type() {
    enum = {"String", "Integer", "Float", "Boolean"};
    exactly(String str) => str in enum;
}
shared object complex extends Type() {
    enum = {};
    exactly(String str) => !str.startsWith("[") && !(str in basic.enum.chain(anything.enum).chain(stringParsed.enum));
}
shared object anything extends Type() {
    enum = {"Anything"};
    exactly(String str) => str in enum;
}
shared object stringParsed extends Type() {
    enum = {"Time", "Date", "DateTime", "UUID"};
    exactly(String str) => str in enum;
}
shared object sequenceWithBasic extends Type() {
    enum = {};
    exactly(String str) => str.startsWith("[") && str.containsAny(basic.enum);
}
shared object sequenceWithAnything extends Type() {
    enum = {};
    exactly(String str) => str.startsWith("[") && str.containsAny(anything.enum);
}
shared object sequenceWithComplex extends Type() {
    enum = {};
    exactly(String str) => str.startsWith("[") && !(str in basic.enum.chain(anything.enum).chain(stringParsed.enum));
}
shared object sequenceWithStringParsed extends Type() {
    enum = {};
    exactly(String str) => str.startsWith("[") && str.containsAny(stringParsed.enum) ;
}
