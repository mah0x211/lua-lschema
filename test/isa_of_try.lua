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
for _, typ in ipairs({
    'string',
    'number',
    'unsigned',
    'int',
    'int8',
    'int16',
    'int32',
    'uint8',
    'uint16',
    'uint32',
    'boolean',
    'table',
    'enum',
    'struct'
}) do
    isa = myschema.isa( typ );
    if typ == 'enum' then
        ifNotTrue(isolate(function()
            isa:of( myschema.enum.myenum );
            isa:makeCheck();
        end));
        
        -- valid validation
        _, err = isa( 'name1' );
        ifNotNil( err );
        
        _, err = isa( 'name2' );
        ifNotNil( err );
        
        -- invalid validation
        _, err = isa( 1 );
        ifNil( err );
        ifNotEqual( err.errno, errno.ETYPE );
        ifNotEqual( err.etype, 'ETYPE' );
        
        _, err = isa( 'name3' );
        ifNil( err );
        ifNotEqual( err.errno, errno.EENUM );
        ifNotEqual( err.etype, 'EENUM' );
        
    elseif typ == 'struct' then
        ifNotTrue(isolate(function()
            isa:of( myschema.struct.mystruct );
            isa:makeCheck();
        end));
        
        -- valid validation
        _, err = isa({ field = 'string' });
        ifNotNil( err );
        
        -- invalid validation
        _, err = isa( 1 );
        ifNil( err );
        ifNotEqual( err.errno, errno.ETYPE );
        ifNotEqual( err.etype, 'ETYPE' );
        
        _, err = isa({ field = 1 });
        ifNil( err );
        ifNotEqual( err.field.errno, errno.ETYPE );
        ifNotEqual( err.field.etype, 'ETYPE' );
        
    -- does not support a of attribute
    else
        -- attempted to access to undefined value
        ifTrue(isolate(function()
            local fn = isa.of;
        end));
    end
    
    -- array
    -- does not support array
    if typ == 'table' then
        ifTrue(isolate(function()
            isa = myschema.isa( typ .. '[]' );
        end));
    else
        isa = myschema.isa( typ .. '[]' );
        if typ == 'enum' then
            ifNotTrue(isolate(function()
                isa:of( myschema.enum.myenum );
                isa:makeCheck();
            end));
            
            -- valid validation
            _, err = isa({ 'name1' });
            ifNotNil( err );
            
            _, err = isa({ 'name1', 'name2' });
            ifNotNil( err );
            
            -- invalid validation
            _, err = isa( 1 );
            ifNil( err );
            ifNotEqual( err.errno, errno.ETYPE );
            ifNotEqual( err.etype, 'ETYPE' );
            
            _, err = isa( 'name3' );
            ifNil( err );
            ifNotEqual( err.errno, errno.ETYPE );
            ifNotEqual( err.etype, 'ETYPE' );
            
            _, err = isa({ 'name1', 'name2', 'name3' });
            ifNotEqual( err[3].errno, errno.EENUM );
            ifNotEqual( err[3].etype, 'EENUM' );

        elseif typ == 'struct' then
            ifNotTrue(isolate(function()
                isa:of( myschema.struct.mystruct );
                -- for strict checking
                isa:notNull();
                isa:makeCheck();
            end));

            -- valid validation
            _, err = isa({
                { field = 'string' }
            });
            ifNotNil( err );
            
            -- invalid validation
            -- not null constraint
            _, err = isa({ field = 'string' });
            ifNil( err );
            ifNotEqual( err.errno, errno.ENULL );
            ifNotEqual( err.etype, 'ENULL' );
            
            _, err = isa( 1 );
            ifNil( err );
            ifNotEqual( err.errno, errno.ETYPE );
            ifNotEqual( err.etype, 'ETYPE' );
            
            _, err = isa({
                { field = 'string' },
                { field = 1 }
            });
            ifNil( err );
            ifNotEqual( err[2].field.errno, errno.ETYPE );
            ifNotEqual( err[2].field.etype, 'ETYPE' );

        -- does not support a of attribute
        else
            -- attempted to access to undefined value
            ifTrue(isolate(function()
                local fn = isa.of;
            end));
        end
    end
end
