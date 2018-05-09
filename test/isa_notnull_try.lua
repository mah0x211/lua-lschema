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
    isa = myschema.isa( typ );
    if typ == 'enum' then
        isa:of(myschema.enum.myenum);
    elseif typ == 'struct' then
        isa:of(myschema.struct.mystruct);
    end

    -- invalid definition: argument disallowed
    ifTrue(isolate(function()
        isa:notNull(1);
    end));

    -- valid defintion
    ifNotTrue(isolate(function()
        isa:notNull();
        -- should not redefine
        ifTrue(isolate(function()
            isa:notNull();
        end));
        isa:makeCheck();
    end));

    -- valid validation
    _, err = isa( val );
    ifNotNil( err );
    -- invalid validation
    _, err = isa();
    ifNotEqual( err.errno, errno.ENULL );
    ifNotEqual( err.etype, 'ENULL' );

    -- array
    -- does not support array
    if typ == 'table' then
        ifTrue(isolate(function()
            isa = myschema.isa( typ .. '[]' );
        end));
    else
        isa = myschema.isa( typ .. '[]' );
        if typ == 'enum' then
            isa:of(myschema.enum.myenum);
        elseif typ == 'struct' then
            isa:of(myschema.struct.mystruct);
        end

        -- invalid difinition: argument disallowed
        ifTrue(isolate(function()
            isa:notNull(1);
        end));
        -- valid difinition
        ifNotTrue(isolate(function()
            isa:notNull();
            -- should not redefine
            ifTrue(isolate(function()
                isa:notNull();
            end));
            isa:makeCheck();
        end));

        -- valid validation
        _, err = isa( {val} );
        ifNotNil( err );
        -- invalid validation
        _, err = isa();
        ifNotEqual( err.errno, errno.ENULL );
        ifNotEqual( err.etype, 'ENULL' );
    end
end
