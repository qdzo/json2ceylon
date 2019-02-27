/*
   File generated by `ru.qdzo.ceylon.json2ceylon` tool at 2019-02-27T23:41:11.770.
 */

import java.util {
    UUID
}
import ceylon.time {
    DateTime
}
import ceylon.time.iso8601 {
    parseDateTime
}
import ceylon.json {
    parseJson = parse,
    JsonObject
}


shared class User {
    shared UUID uid;
    shared String name;
    shared Address address;
    shared String role;
    shared DateTime registered;
    shared Activity activity;

    shared new (
            UUID uid,
            String name,
            Address address,
            String role,
            DateTime registered,
            Activity activity
            ) {

        this.uid = uid;
        this.name = name;
        this.address = address;
        this.role = role;
        this.registered = registered;
        this.activity = activity;
    }

    UUID|Exception parseUUID(String str){
        try {
            return UUID.fromString(str);
        } catch(Exception e) {
            return Exception("Can't parse UUID string: " + str + ", error: " + e.message);
        }
    }

    shared new fromJson(String|JsonObject json) {
        assert(is JsonObject jsObj = switch(json) case(is JsonObject) json else parseJson(json));
        assert(is String uidStr = jsObj.get("uid"),
               is UUID uid = parseUUID(uidStr));
        assert(is String name = jsObj.get("name"));
        assert(is JsonObject addressJsObj = jsObj.get("address"));
        Address address = Address.fromJson(addressJsObj);
        assert(is String role = jsObj.get("role"));
        assert(is String registeredStr = jsObj.get("registered"),
               is DateTime registered = parseDateTime(registeredStr));
        assert(is JsonObject activityJsObj = jsObj.get("activity"));
        Activity activity = Activity.fromJson(activityJsObj);

        this.uid = uid;
        this.name = name;
        this.address = address;
        this.role = role;
        this.registered = registered;
        this.activity = activity;
    }

    shared JsonObject toJson => JsonObject {
        "uid" -> uid.string,
        "name" -> name,
        "address" -> address.toJson,
        "role" -> role,
        "registered" -> registered.string,
        "activity" -> activity.toJson
    };

    shared actual String string => toJson.string;
}