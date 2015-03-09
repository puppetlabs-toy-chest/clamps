TODO items:

 - The name `logic`: in the `clamps:` section of the config file is an opaque name. Change this to something that users can understand.

 - Replace classification of nodes with `pe_mcollective` for it to work, right now it only works with a single master / activemq broker due to janky `server.cfg` creation for mcollective.

 - This is now three classes that you have to use the PE 3.4 Node Manager to classify the servers with (since this also lets us test the NC now).

 - Modify the `pe_mcollective` rule in the console to require `$id = root`.
