# Ceylon class generation examples

Create json file

user.json:

    {
      "uid" : "6434723B-F8E4-4A5A-BAFF-8467A239527F",
      "name" : "Vitaly",
      "address" : {
        "street" : "Gagarin",
        "house" : 55
      },
      "role": "Dev",
      "registered" : "2019-01-01T12:00:00",
      "activity": {
        "lastLogin": "2019-02-27",
        "lastActivity": "23:22:00"
      }
    }

## Generate simple classes

run `./generate.sh`

Files generated and saved to **gen** dir.


## Generate externalizable classes

> Externalizable means that class has its own serializer/deserializer.

run `./generate_exernalizable.sh`

Files generated and saved to **gen_ext** dir.


