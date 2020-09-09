import com.redhat.ceylon.common.tool {
    CeylonBaseTool,
    summary,
    description,
    description__SETTER,
    argument__SETTER,
    option__SETTER
}
import java.util {
    JList = List
}

summary("generate ceylon classes from given json file")
description("Generate ceylon classes from json file. 
             Also can generate additional serializers/deserializers for classes.

             Args: 

              * file       - with json object,
              * directory  - for storing generated classes
              * class name - for root class naming 

             Example: 

               ceylon json-2-ceylon file.json out_dir \"RootClassName\"
              ")
shared class Json2CeylonTool() extends CeylonBaseTool() {

    argument__SETTER { multiplicity = "*"; }
    shared variable JList<String>? arguments = null;

    description__SETTER("Create externalizable class with embedded json parser/emitter")
    option__SETTER
    shared variable Boolean externalizable = false;

    shared actual void run() {
       if(exists v = arguments) {
         if(v.size() == 3) {
            try {
                json2ceylon {
                    inputFile = v.get(0).string;
                    outputDir = v.get(1).string;
                    clazzName = v.get(2).string;
                    externalizable = externalizable;
                };
            } catch(Throwable th) {
                print(errorMsgWithHelp(th.message));
            }
         } else {
           print(errorMsgWithHelp("Should be 3 arguments, but was ``v.size()``"));
         }
       } else {
           print(errorMsgWithHelp("Empty arguments"));
       }
    }
}

String errorMsgWithHelp(String error) => 
    "Error: ``error``

        Usage: 
            ceylon json-2-ceylon json-file output-dir RootClassName

        Try `ceylon json-2-ceylon --help` for details";