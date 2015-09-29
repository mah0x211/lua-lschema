local errno = require('lschema.ddl.errno');
local lschema = require('lschema');
local myschema = ifNil( lschema.new('myschema') );
local enum = myschema.enum;


-- indentity pattern: ^[_a-zA-Z][_a-zA-Z0-9]*$
-- invalid ident
ifTrue(isolate(function()
    enum '' {}
end));
ifTrue(isolate(function()
    enum 'my-enum' {}
end));
ifTrue(isolate(function()
    enum 'my.enum' {}
end));

-- test enum field ident
-- invalid ident
ifTrue(isolate(function()
    enum 'myenum' {
        1
    }
end));
ifTrue(isolate(function()
    enum 'myenum' {
        'name-1'
    }
end));
ifTrue(isolate(function()
    enum 'myenum' {
        'name.1'
    }
end));
-- valid ident
ifNotTrue(isolate(function()
    enum 'myenum' {
        'name1',
        'name2'
    }
end));

-- verify definition
ifNil( enum.myenum );
ifNotEqual( 1, enum.myenum.name1 );
ifNotEqual( 2, enum.myenum.name2 );
-- invalid duplicate enum ident
ifTrue(isolate(function()
    enum 'myenum' {}
end));


-- verify behavior
ifNotEqual( enum.myenum('name1'), 'name1' );
ifNotEqual( enum.myenum('name2'), 'name2' );
-- verify error
local res, err = enum.myenum('name3');
local cmp = { 
    errno = errno.EENUM,
    etype = "EENUM",
    attr = { 
        name1 = 1,
        name2 = 2
    }
};
ifNotNil( res );
-- err must be table
ifNotEqual( inspect(err), inspect(cmp) );



