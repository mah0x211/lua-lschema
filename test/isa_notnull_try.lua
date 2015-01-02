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
    -- invalid definition: argument disallowed
    ifTrue(isolate(function()
        if typ == 'enum' then
            isa = myschema.isa( typ ):of(myschema.enum.myenum):notNull(1);
        elseif typ == 'struct' then
            isa = myschema.isa( typ ):of(myschema.struct.mystruct):notNull(1);
        else
            isa = myschema.isa( typ ):notNull(1);
        end
        isa:makeCheck();
    end));
    
    -- valid defintion
    ifNotTrue(isolate(function()
        if typ == 'enum' then
            isa = myschema.isa( typ ):of(myschema.enum.myenum):notNull();
        elseif typ == 'struct' then
            isa = myschema.isa( typ ):of(myschema.struct.mystruct):notNull();
        else
            isa = myschema.isa( typ ):notNull();
        end
        isa:makeCheck();
    end));
    
    -- valid validation
    _, err = isa( val );
    ifNotNil( err );
    -- invalid validation
    _, err = isa();
    ifNotEqual( err.errno, 1 );
    ifNotEqual( err.etype, 'ENULL' );
    
    -- array
    if typ ~= 'table' then
        -- invalid difinition: argument disallowed
        ifTrue(isolate(function()
            if typ == 'enum' then
                isa = myschema.isa( typ .. '[]' ):of(myschema.enum.myenum):notNull(1);
            elseif typ == 'struct' then
                isa = myschema.isa( typ .. '[]' ):of(myschema.struct.mystruct):notNull(1);
            else
                isa = myschema.isa( typ .. '[]' ):notNull(1);
            end
            isa:makeCheck();
        end));
        -- valid difinition
        ifNotTrue(isolate(function()
            if typ == 'enum' then
                isa = myschema.isa( typ .. '[]' ):of(myschema.enum.myenum):notNull();
            elseif typ == 'struct' then
                isa = myschema.isa( typ .. '[]' ):of(myschema.struct.mystruct):notNull();
            else
                isa = myschema.isa( typ .. '[]' ):notNull();
            end
            isa:makeCheck();
        end));
        
        -- valid validation
        _, err = isa( {val} );
        ifNotNil( err );
        -- invalid validation
        _, err = isa();
        ifNotEqual( err.errno, 1 );
        ifNotEqual( err.etype, 'ENULL' );
    end
end
