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
    assert(exists className->fields  = res.first);
    value fields1 = fields.sequence();
    assertEquals(className, "Person");
    assertEquals(fields1[0], ["String", "type"]);
    assertEquals(fields1[1], ["Integer", "age"]);
    assertEquals(fields1[2], ["Float", "money"]);
    assertEquals(fields1[3], ["Boolean", "men"]);
    assertEquals(fields1[4], ["String?", "comment"]);

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
    assert(exists className->fields  = res.find(forKey("Card".equals)));
    value fields1 = fields.sequence();
    assertEquals(className, "Card");
    assertEquals(fields1[0], ["Person", "person"]);
}

test
shared void shouldGenerateSequenceFields() {
    value str = """{
                        "ids": [1, 2, 3, 4, 5],
                        "persons": [
                                      {
                                          "name": "Vitaly",
                                          "age": 20,
                                          "money": 10.7,
                                          "men": true,
                                          "comment": null
                                      },
                                      {
                                          "name": "Ivan",
                                          "age": 10,
                                          "money": 0.0,
                                          "men": true,
                                          "comment": "child"
                                      }
                                    ]
                    }""";
    value res = generateClassInfo(str, "Card");

    assert(exists cardClassName->cardFields  = res.find(forKey("Card".equals)));
    assertEquals(cardClassName, "Card");
    value cardFields1 = cardFields.sequence();
    assertEquals(cardFields1[0], ["[Integer*]", "ids"]);
    assertEquals(cardFields1[1], ["[Person*]", "persons"]);

    assert(exists personClassName->personFields  = res.find(forKey("Person".equals)));
    assertEquals(personClassName, "Person");
    value personFields1 = personFields.sequence();
    assertEquals(personFields1[0], ["String", "name"]);
    assertEquals(personFields1[1], ["Integer", "age"]);
    assertEquals(personFields1[2], ["Float", "money"]);
    assertEquals(personFields1[3], ["Boolean", "men"]);
    assertEquals(personFields1[4], ["String?", "comment"]);
}
