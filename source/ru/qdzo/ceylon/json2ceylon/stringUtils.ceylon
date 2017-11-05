String fieldTemplate(String[2] field)
        => "shared ``field[0]`` ``field[1]``";

String getterFieldTemplate(String[2] field) {
    value [type, name] = field;
    if(type in {"String", "Integer", "Float", "Boolean"}) {
        return "shared ``type`` ``name`` => jsObj.get``type``(\"``name``\");";
    } else {
        return "shared ``type`` ``name`` => ``type``(jsObj.getObject(\"``name``\"));";
    }
}

String makeClazzName(String str)
        => str[0..0].uppercased +
            (str.endsWith("s") && !str.endsWith("ss")
                then str[1..str.size-2]
                else str.rest);

String makeFieldName(String str)
        => str[0..0].lowercased + str.rest;

