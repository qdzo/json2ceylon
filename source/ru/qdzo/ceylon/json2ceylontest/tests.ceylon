import ru.qdzo.ceylon.json2ceylon {
    generateClassInfo
}
import ceylon.test {
    test,
    assertEquals
}

test
shared void shouldGenerateFieldsWithBasicTypes() {
    value str = """{
                      "type": "Person",
                      "age": 20,
                      "money": 10.7,
                      "men": true,
                      "comment": null
                   }
                   """;
    value res = generateClassInfo(str, "Person");
    assert(exists className->fields1  = res.first);
    value fields = fields1.sequence();
    assertEquals(className, "Person");
    assertEquals(fields[0], ["String", "type"]);
    assertEquals(fields[1], ["Integer", "age"]);
    assertEquals(fields[2], ["Float", "money"]);
    assertEquals(fields[3], ["Boolean", "men"]);
    assertEquals(fields[4], ["String?", "comment"]);

}

test
shared void shouldGenerateFieldsWithNestedTypes() {
    value str = """{
                        "person": {
                            "type": "Person",
                            "age": 20,
                            "money": 10.7,
                            "men": true,
                            "comment": null
                        }
                    }""";
    value res = generateClassInfo(str, "Card");
    assert(exists className->fields1  = res.find(forKey("Card".equals)));
    value fields = fields1.sequence();
    assertEquals(className, "Card");
    assertEquals(fields[0], ["Person", "person"]);
}
