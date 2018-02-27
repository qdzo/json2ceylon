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
    assertEquals(fields1[4], ["Anything", "comment"]);

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
    assertEquals(personFields1[4], ["Anything", "comment"]);
}

test
shared void shouldGenerateFieldsWithStringParsedTypes() {
    value str = """{
                        "uuid": "6f1591a7-b221-4eed-9935-5427d851dfa9",
                        "datetime": "2018-01-29T17:49:13",
                        "date": "2018-01-29",
                        "time": "17:49:13",
                        "uuids": ["6f1591a7-b221-4eed-9935-5427d851dfa9"],
                        "datetimes": [ "2018-01-29T17:49:13", "2018-02-29T17:49:00" ],
                        "dates": [ "2018-01-29", "2018-02-01" ],
                        "times": [ "17:49:13", "18:08:00" ]
                    }""";
    value res = generateClassInfo(str, "TimeCard");
    assert(exists cardClassName->cardFields  = res.find(forKey("TimeCard".equals)));
    assertEquals(cardClassName, "TimeCard");
    value cardFields1 = cardFields.sequence();
    assertEquals(cardFields1[0], ["UUID", "uuid"]);
    assertEquals(cardFields1[1], ["DateTime", "datetime"]);
    assertEquals(cardFields1[2], ["Date", "date"]);
    assertEquals(cardFields1[3], ["Time", "time"]);
    assertEquals(cardFields1[4], ["[UUID*]", "uuids"]);
    assertEquals(cardFields1[5], ["[DateTime*]", "datetimes"]);
    assertEquals(cardFields1[6], ["[Date*]", "dates"]);
    assertEquals(cardFields1[7], ["[Time*]", "times"]);
}
