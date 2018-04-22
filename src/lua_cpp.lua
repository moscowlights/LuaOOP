--[[ ----------------------------------------------------------------------------------------------
 File       : lua_cpp.lua
 Description: OOP paradigm with pseudo C++ methods
 Copyright  : 2018 © Karlan
 Author(s)  : Karlan
 Dependencies: lua_extensions.lua
--]] ----------------------------------------------------------------------------------------------

local Protected =
{
    __type      = true
    __name      = true
    __bases     = true
    __class     = true
    __index     = true
    __static    = true
}

local ClassMeta    =
{
    __Construct    = function( this )
        local obj        =
        {
            __type            = "object"
        }

        setmetatable( obj, this )

        for i, CClass in ipairs( this.__bases ) do
            rawset( obj, CClass.__name, CClass[ CClass.__name ] )
        end

        return obj
    end

    __call        = function( this, ... )
        local obj = this:__Construct()

        local res = nil

        if this[ this.__name ] then
            res = this[ this.__name ]( obj, ... )
        end

        return res == nil and obj or res
    end

    __tostring    = function( this )
        return typeof( this ) + ": " + classname( this )
    end
}

ClassMeta.__index    = ClassMeta

class            =
{
    __newindex    = function( this )
        return nil
    end

    __index        = function( this, name )
        local env            = _G
        local names            = name:split( "." )
        local class_name    = names[ #names ]

        table.remove( names )

        for i, name_space in ipairs( names ) do
            if type( env[ name_space ] ) == "table" then
                env = env[ name_space ]
            else
                print("attempt to index '", name_space, "' in ", name)
            end
        end

        local TClass    = this:Create( class_name, true )

        env[ class_name ] = TClass

        return function( this, ... )
            local Args1    = { ... }

            if typeof( Args1[ 1 ] ) == "class" then
                this:SetBases( TClass, Args1 )

                return function( ... )
                    this:SetValues( TClass, ... )
                end
            end

            this:SetValues( TClass, ... )
        end
    end

    __call        = function( this, name )
        local env            = _G
        local names            = name:split( "." )
        local class_name    = names[ #names ]

        table.remove( names )

        for i, name_space in ipairs( names ) do
            if type( env[ name_space ] ) == "table" then
                env = env[ name_space ]
            else
                print("attempt to index '", name_space, "' in ", name)
            end
        end

        local TClass    = this:Create( class_name, true )

        env[ class_name ] = TClass

        return function( ... )
            local arg    = { ... }

            if typeof( arg[ 1 ] ) == "class" then
                this:SetBases( TClass, arg )

                return function( ... )
                    this:SetValues( TClass, ... )
                end
            end

            this:SetValues( TClass, ... )
        end
    end

    Create        = function( this, name )
        local CClass    =
        {
            __type        = "class"
            __name        = name
            __bases        = {}
        }

        CClass.__class     = CClass
        CClass.__index     = CClass

        setmetatable( CClass, ClassMeta )

        return CClass
    end

    SetBases    = function( this, CClass, bases )
        CClass.__bases = bases

        for i, _CClass in ipairs( CClass.__bases ) do
            for key, value in pairs( _CClass ) do
                if not Protected[ key ] then
                    if type( value ) == 'function' and ( not CClass.__static or not CClass.__static[ key ] ) then
                        CClass[ key ]    = function( ... )
                            return _CClass[ key ]( ... )
                        end
                    else
                        CClass[ key ]    = value
                    end
                end
            end
        end
    end

    SetValues    = function( this, CClass, values )
        if not values then
            print("Couldn't inherit classes to ", classname( CClass ), " class." )
            return
        end

        for key, value in pairs( values ) do
            if not Protected[ key ] then
                if tonumber( key ) and type( value ) == "table" and value.__static then
                    if not CClass.__static then
                        CClass.__static = {}
                    end

                    for k, v in pairs( value ) do
                        if not Protected[ k ] then
                            CClass.__static[ k ] = true
                            CClass[ k ] = v
                        end
                    end
                else
                    CClass[ key ] = value
                end
            end
        end

        if not CClass[ CClass.__name ] then
            CClass[ CClass.__name ] = function(self) end
        end
    end
}

setmetatable( class, class )

new        =
{
    __index        = function( this, name )
        local class    = _G[ name ]

        return class and class:__Construct()
    end
}

setmetatable( new, new )

function static( values )
    values.__static = true

    return values
end

function virtual( CClass )
    return typeof( CClass ) == "class" and { __type = "virtual_class", __class = CClass } or print("Argument is not a class")
end

function typeof( void )
    return void and void.__type or type( void )
end

function classof( void )
    if type( void ) == "table" or type( void ) == "userdata" then
        return void.__class
    end

    return nil
end

function classname( void )
    if type( void ) == "table" or type( void ) == "userdata" then
        return void.__name
    end

    return nil
end

function delete( obj )
    if not classof( obj ) then return end
    local is_ud = type( obj ) ~= "table"
            
    if obj[ '_' .. obj.__name ] then
        obj[ '_' .. obj.__name ]( obj )
    end

    if not is_ud then
        setmetatable( obj, nil )
    else
        --// On this place can call __gc metamethod, if you use another constructions in children classes
    end
    
    obj = nil
end
