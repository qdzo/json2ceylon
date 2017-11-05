shared String->String printClass(Boolean serializable)(String->{[String, String]*} classInfo) {
    value builder = StringBuilder();
    value className->fields = classInfo;
    if(serializable) {
        builder.append("serializable\n");
    }
    builder.append("shared class ``className``(\n``indent``");
    builder.append(",\n``indent``".join(fields.map(fieldTemplate)));
    builder.append("\n) {}");
    return className->builder.string;
}

