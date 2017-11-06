shared String->String printClass(Boolean serializable)(String->{[String, String]*} classInfo) {
    value builder = StringBuilder();
    value className->fields = classInfo;
    if(serializable) {
        builder.append("serializable\n");
    }
    builder.append("shared class ``className``(\n    ");
    builder.append(",\n    ".join(fields.map(fieldTemplate)));
    builder.append("\n) {}");
    return className->builder.string;
}

// experiments with generating self deserializable class
shared String->String printExternalizableClass(String->{[String, String]*} classInfo) {
    value builder = StringBuilder();
    value className->fields = classInfo;
    builder.append("import ceylon.json { parse, JsonObject }
    
                    shared class ``className``(String|JsonObject json) {
                        assert(is JsonObject jsObj =
                                    switch(json)
                                    case(is JsonObject) json
                                    else parse(jsonStr));

                        ");
    builder.append("\n    ".join(fields.map(getterFieldTemplate)));
    builder.append("\n}");
    return className->builder.string;
}


