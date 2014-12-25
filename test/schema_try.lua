local lschema = require('lschema');

-- indentity pattern: ^[_a-zA-Z][_a-zA-Z0-9]*$
-- invalid
ifTrue(isolate(function()
    lschema.new('');
end));
ifTrue(isolate(function()
    lschema.new('my-schema');
end));
ifTrue(isolate(function()
    lschema.new('my.schema');
end));

-- valid
local myschema = ifNil( lschema.new('myschema') );
-- check declarators
ifNil( myschema.isa );
ifNil( myschema.enum );
ifNil( myschema.struct );
ifNil( myschema.pattern );

