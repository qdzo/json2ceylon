/*
   File generated by `ru.qdzo.ceylon.json2ceylon` tool at 2019-02-27T23:41:11.788.
 */

import ceylon.json {
    parseJson = parse,
    JsonObject
}


shared class Address {
    shared String street;
    shared Integer house;

    shared new (
            String street,
            Integer house
            ) {

        this.street = street;
        this.house = house;
    }

    

    shared new fromJson(String|JsonObject json) {
        assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parseJson(json));
        assert(is String street = jsObj.get("street"));
        assert(is Integer house = jsObj.get("house"));

        this.street = street;
        this.house = house;
    }

    shared JsonObject toJson => JsonObject {
        "street" -> street,
        "house" -> house
    };

    shared actual String string => toJson.string;
}