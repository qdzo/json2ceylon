String indent = "    ";

String fieldTemplate(String[2] field)
        => "shared ``field[0]`` ``field[1]``";

String makeClazzName(String str)
        => str[0..0].uppercased +
            (str.endsWith("s") && !str.endsWith("ss")
                then str[1..str.size-2]
                else str.rest);

String makeFieldName(String str)
        => str[0..0].lowercased + str.rest;

