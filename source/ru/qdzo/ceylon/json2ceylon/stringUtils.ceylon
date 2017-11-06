String fieldTemplate(String[2] field)
        => "shared ``field[0]`` ``field[1]``";

String formatClazzName(String str)
        => str[0..0].uppercased +
            (str.endsWith("s") && !str.endsWith("ss") // may be plural - cut last 's' char
                then str[1..str.size-2]
                else str.rest);

String formatFieldName(String str)
        => str[0..0].lowercased + str.rest;

