/*
   File generated by `ru.qdzo.ceylon.json2ceylon` tool at 2019-02-27T23:36:35.463.
 */

import java.util {
    UUID
}
import ceylon.time {
    DateTime
}


serializable
shared class User(
    shared UUID uid,
    shared String name,
    shared Address address,
    shared String role,
    shared DateTime registered,
    shared Activity activity
) {}