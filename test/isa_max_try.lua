local errno = require('lschema.ddl.errno');
local lschema = require('lschema');
local myschema = lschema.new('myschema');
local isa, err, _;

-- set enum
myschema.enum 'myenum' {
    'name1',
    'name2'
}

myschema.struct 'mystruct' {
    field = myschema.isa('string')
};

-- isa type
for typ, val in pairs({
    ['string'] = 'str',
    ['number'] = 1,
    ['unsigned'] = 1,
    ['int'] = 1,
    ['int8'] = 1,
    ['int16'] = 1,
    ['int32'] = 1,
    ['uint8'] = 1,
    ['uint16'] = 1,
    ['uint32'] = 1,
    ['boolean'] = true,
    ['table'] = {},
    ['enum'] = 'name1',
    ['struct'] = { field = 'str' }
}) do
    -- does not support max constraint
    if typ == 'boolean' or typ == 'table' or typ == 'enum' or typ == 'struct' then
        ifTrue(isolate(function()
            isa = myschema.isa( typ ):max();
            isa:makeCheck();
        end));
        ifTrue(isolate(function()
            isa = myschema.isa( typ ):max( 1 );
            isa:makeCheck();
        end));
    else
        -- invalid definition: no argument
        ifTrue(isolate(function()
            isa = myschema.isa( typ ):max();
            isa:makeCheck();
        end));
        
        -- valid defintion
        ifNotTrue(isolate(function()
            if typ == 'string' then
                isa = myschema.isa( typ ):max( #val );
            else
                isa = myschema.isa( typ ):max( val );
            end
            isa:makeCheck();
        end));
        
        -- valid validation
        _, err = isa( val );
        ifNotNil( err );
        -- invalid validation
        if typ == 'string' then
            _, err = isa( val .. val );
        else
            _, err = isa( val + 1 );
        end
        ifNotEqual( err.errno, errno.EMAX );
        ifNotEqual( err.etype, 'EMAX' );
        
        -- array
        -- invalid difinition: no argument
        ifTrue(isolate(function()
            isa = myschema.isa( typ .. '[]' ):max();
            isa:makeCheck();
        end));
        -- valid difinition
        ifNotTrue(isolate(function()
            if typ == 'string' then
                isa = myschema.isa( typ .. '[]' ):max( #val );
            else
                isa = myschema.isa( typ .. '[]' ):max( val );
            end
            isa:makeCheck();
        end));
        
        -- valid validation
        _, err = isa( {val} );
        ifNotNil( err );
        -- invalid validation
        if typ == 'string' then
            _, err = isa( {val .. val} );
        else
            _, err = isa( {val + 1} );
        end
        ifNotEqual( err[1].errno, errno.EMAX );
        ifNotEqual( err[1].etype, 'EMAX' );
    end
end
