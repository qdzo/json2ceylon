shared String->String emitClass(String->{[String, String]*} classInfo) {
    value className->fields = classInfo;
    value uniqTypes = set(fields.map(([t, v]) => t));
    value classContent =
            "``emitAdditionalImports(uniqTypes)``

             serializable
             shared class ``className``(
                 ``defineFieldsInConstructor(fields, 1)``
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
                            ``defineConstructorProps(fields, 3)``
                            ) {

                        ``assignFields(fields, 2)``
                    }

                    ``uniqTypes.contains("UUID") then defineParseUUIDFn() else ""``

                    shared new fromJson(String|JsonObject json) {
                        assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parseJson(json));
                        ``assertFields(fields, 2)``

                        ``assignFields(fields, 2)``
                    }

                    shared JsonObject toJson => JsonObject {
                        ``fieldsToJsonEntries(fields, 2)``
                    };

                }";
value importLines = emitAdditionalImports(findAdditionalJsonTypesForImport(uniqTypes));
    return className-> importLines + "\n\n" + classContent;
}

String defineParseUUIDFn() => "UUID(String) parseUUID = UUID.fromString;";

String defineFields({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize),
            semicolonWithIndent = ";" + indent)
            semicolonWithIndent.join(fields.map(sharedFieldTemplate));

String defineFieldsInConstructor({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize),
            commaWithIndent = "," + indent)
            commaWithIndent.join(fields.map(sharedFieldTemplate));

String defineConstructorProps({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize),
               commaWithIndent = "," + indent)
               commaWithIndent.join(fields.map(fieldTemplate));

String fieldsToJsonEntries({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize),
               commaWithIndent = "," + indent)
               commaWithIndent.join(fields.map((field) => fieldToJsonEntry(*field)));

String fieldToJsonEntry(String type, String name) {
    value escapedName = escapeCeylonKeywords(name);
    return switch (describeType(type))
           case (basic) "\"``name``\" -> ``escapedName``"
           case (complex) "\"``name``\" -> ``escapedName``.toJson"
           case (anything) "\"``name``\" -> ``escapedName``"
           case (stringParsed) "\"``name``\" -> ``escapedName``.string"
           case (sequenceWithBasic) "\"``name``\" -> JsonArray(``escapedName``)"
           case (sequenceWithAnything) "\"``name``\" -> JsonArray(``escapedName``)"
           case (sequenceWithComplex) "\"``name``\" -> JsonArray(``escapedName``*.toJson)"
           case (sequenceWithStringParsed) "\"``name``\" -> JsonArray(``escapedName``*.string)";
}

String assertFields({String[2]*} fields, Integer indentSize)
        => "\n".join(fields.map(([type, name]) => assertField(type, name, indentSize))).trimLeading(' '.equals);

String assertField(String type, String name, Integer indentSize) {
    value indent = makeIndent(indentSize);
    value escapedName = escapeCeylonKeywords(name);
    switch (describeType(type))
    case (basic) {
        return "``indent``assert(is ``type`` ``escapedName`` = jsObj.get(\"``name``\"));";
    }
    case (anything) {
        return "``indent``assert(is ``type`` ``escapedName`` = jsObj.get(\"``name``\"));";
    }
    case (complex) {
        return "``indent``assert(is JsonObject ``name``JsObj = jsObj.get(\"``name``\"));
                ``indent````type`` ``escapedName`` = ``type``.fromJson(``name``JsObj);";
    }
    case (stringParsed) {
        return "``indent``assert(is String ``name``Str = jsObj.get(\"``name``\"),
                ``indent``       is ``type`` ``escapedName`` = parse``type``(``name``Str));";
    }
    case (sequenceWithBasic) {
        if (arrayDepth(type) == 1) {
            return "``indent``assert(is ``type`` ``escapedName`` = jsObj.getArray(\"``name``\").narrow<``trimArrayChars(type)``>());"; // BUG: supports only one nesting level
        }
        return "";
    }
    case (sequenceWithComplex) {
        if (arrayDepth(type) == 1) {
            return "``indent``assert(is [JsonObject*] ``name``jsObjs = jsObj.getArray(\"``name``\").narrow<JsonObject>().sequence(),
                    ``indent``       is ``type`` ``escapedName`` = ``name``JsObjs.collect(``trimArrayChars(type)``.fromJson));";
        }
        return "";
    }
    case (sequenceWithAnything) {
        if (arrayDepth(type) == 1) {
            return "``indent``assert(is [Anything*] ``escapedName`` = jsObj.getArray(\"``name``\").sequence());";
        }
        return "";
    }
    case (sequenceWithStringParsed) {
        if (arrayDepth(type) == 1) {
            return "``indent``assert(is [String*] ``name``Strs = jsObj.getArray(\"``name``\").narrow<String>().sequence(),
                    ``indent``       is ``type`` ``escapedName`` = ``name``Strs.map(parse``trimArrayChars(type)``).narrow<``trimArrayChars(type)``>().sequence());";
        }
        return "";
    }
}

String assignFields({String[2]*} fields, Integer indentSize)
        => let(indent = makeIndentWithNewLine(indentSize))
            indent.join(fields.map(([_,name]) => let(escapedName = escapeCeylonKeywords(name)) "this.``escapedName`` = ``escapedName``;"));

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
    exactly(String str) => !isArrayType(str) && !(str in basic.enum.chain(anything.enum).chain(stringParsed.enum));
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
    exactly(String str) => isArrayType(str) && str.containsAny(basic.enum);
}
shared object sequenceWithAnything extends Type() {
    enum = {};
    exactly(String str) => isArrayType(str) && trimArrayChars(str) in anything.enum;
}
shared object sequenceWithComplex extends Type() {
    enum = {};
    exactly(String str) => isArrayType(str) && !(trimArrayChars(str) in basic.enum.chain(anything.enum).chain(stringParsed.enum));
}
shared object sequenceWithStringParsed extends Type() {
    enum = {};
    exactly(String str) => isArrayType(str) && trimArrayChars(str) in stringParsed.enum ;
}
