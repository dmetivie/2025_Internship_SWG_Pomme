function myfun(a, b, c, d, e, f, g, h)
    return a + b + c + d + e + f + g + h
end

vecparams = rand(8)                     # Vector{Float64}
tuplparams = Tuple(vecparams)          # NTuple{8, Float64}
namedparams = (; a=vecparams[1], b=vecparams[2], c=vecparams[3], d=vecparams[4],
                 e=vecparams[5], f=vecparams[6], g=vecparams[7], h=vecparams[8])

# Benchmark slow: each vecparams[i] is a runtime dispatch
@btime myfun(vecparams[1], vecparams[2], vecparams[3], vecparams[4],
             vecparams[5], vecparams[6], vecparams[7], vecparams[8])

# Benchmark fast: Tuple splatting
@btime myfun(tuplparams...)

# Benchmark fast: NamedTuple splatting
@btime myfun(namedparams...)

struct MyParams
    a::Float64
    b::Float64
    c::Float64
    d::Float64
    e::Float64
    f::Float64
    g::Float64
    h::Float64
end

function myfun_struct_fields(p::MyParams)
    return myfun(p.a, p.b, p.c, p.d, p.e, p.f, p.g, p.h)
end
pstruct = MyParams(vecparams...)

@btime myfun_struct_fields(pstruct)

struct MyParams2{T}
    a::T
    b::T
    c::T
    d::T
    e::T
    f::T
    g::T
    h::T
end

struct MyParams4{T<:Real}
    a::T
    b::T
    c::T
    d::T
    e::T
    f::T
    g::T
    h::T
end

struct MyParams3
    a
    b
    c
    d
    e
    f
    g
    h
end

pstruct2 = MyParams2(vecparams...)

pstruct3 = MyParams3(vecparams...)

pstruct4 = MyParams4(vecparams...)


function myfun_struct_fields(p::MyParams2)
    return myfun(p.a, p.b, p.c, p.d, p.e, p.f, p.g, p.h)
end

function myfun_struct_fields(p::MyParams3)
    return myfun(p.a, p.b, p.c, p.d, p.e, p.f, p.g, p.h)
end

function myfun_struct_fields(p::MyParams4)
    return myfun(p.a, p.b, p.c, p.d, p.e, p.f, p.g, p.h)
end
@btime myfun_struct_fields(pstruct2)

@btime myfun_struct_fields(pstruct3)

@btime myfun_struct_fields(pstruct4)


using ConcreteStructs

@concrete struct MyParams5
    a
    b
    c
    d
    e
    f
    g
    h
end

function myfun_struct_fields(p::MyParams5)
    return myfun(p.a, p.b, p.c, p.d, p.e, p.f, p.g, p.h)
end

pstruct5 = MyParams5(vecparams...)


@btime myfun_struct_fields(pstruct5)
