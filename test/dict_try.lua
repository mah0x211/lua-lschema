local lschema = require('lschema');
local myschema = ifNil( lschema.new('myschema') );
local dict = myschema.dict;
local isa = myschema.isa;
local res, err;

-- indentity pattern: ^[_a-zA-Z][_a-zA-Z0-9]*$
-- invalid ident
ifTrue(isolate(function()
    dict '' {}
end));
ifTrue(isolate(function()
    dict 'my-dict' {}
end));
ifTrue(isolate(function()
    dict 'my.dict' {}
end));

-- test dict field
-- invalid ident
ifTrue(isolate(function()
    dict 'mydict' {
        1
    }
end));
ifTrue(isolate(function()
    dict 'mydict' {
        'name-1'
    }
end));
ifTrue(isolate(function()
    dict 'mydict' {
        key = 'key',
        val = 'val'
    }
end));
-- valid ident
ifNotTrue(isolate(function()
    dict 'mydict' {
        key = isa('string'):notNull():max(5):default('hello'),
        val = isa('uint8'):notNull():max(15):default(14),
    }
end));


-- verify definition
ifNil( dict.mydict );
ifNil( dict.mydict.key );
ifNil( dict.mydict.val );
-- invalid duplicate dict ident
ifTrue(isolate(function()
    dict 'mydict' {}
end));


-- verify behavior
res, err = dict.mydict('name1');
ifNil( err, 'invalid impriments' );

res, err = dict.mydict({ [1] = 'hello' });
ifNil( err, 'invalid impriments' );

res, err = dict.mydict({ hello = 'worlds', fields = '24' }, true );
ifNil( err, 'invalid impriments' );

res, err = dict.mydict({ field = 4, item = '12' }, true );
ifNil( res, 'invalid impriments' );
ifNotNil( err, 'invalid impriments' );


