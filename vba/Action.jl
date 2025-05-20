# Define a generic AbstractAction abstract type
"""
# Example for chilling model
    chill_model = LinearAction(10.0, 5.0)  # TC = 10, Ec = 5
    T = 7.0
    Rc(T, chill_model)  # Should return (10 - 7) / 5 = 0.6

# Example for forcing model
    force_model = SigmoidalAction(15.0, 3.0)  # Tf = 15, Ef = 3
    T = 18.0
    Rf(T, force_model)  # Should return a value based on the sigmoidal equation
"""
abstract type AbstractAction end

# Concrete types for chilling models with their parameters

struct BinaryAction{F<:Real} <: AbstractAction
    TC::F  # Chilling threshold
end

struct LinearAction{F<:Real} <: AbstractAction
    TC::F  # Chilling threshold
    Ec::F  # Scaling factor
end

struct ExponentialAction{F<:Real} <: AbstractAction
    TC::F  # Chilling threshold
end

struct SigmoidalAction{F<:Real} <: AbstractAction
    TC::F  # Chilling threshold
    Ec::F  # Scaling factor
end

struct TriangularAction{F<:Real} <: AbstractAction
    TC::F  # Chilling threshold
    Ec::F  # Scaling factor
end

struct ParabolicAction{F<:Real} <: AbstractAction
    TC::F  # Chilling threshold
    Ec::F  # Scaling factor
end

struct NormalAction{F<:Real} <: AbstractAction
    TC::F  # Chilling threshold
    Ec::F  # Scaling factor
end

# Chilling model functions using parameters inside AbstractAction structs

function Rc(T, model::BinaryAction)
    return T < model.TC ? one(T) : zero(T)
end

function Rc(T, model::LinearAction)
    return T < model.TC ? (model.TC - T) / model.Ec : zero(T)
end

function Rc(T, model::ExponentialAction)
    return exp(-T / model.TC)
end

function Rc(T, model::SigmoidalAction)
    return 1 / (1 + exp((T - model.TC) / model.Ec))
end

function Rc(T, model::TriangularAction)
    r = 1 - abs(T - model.TC) / model.Ec
    return r < 0 ? zero(r) : r
end

function Rc(T, model::ParabolicAction)
    r = 1 - ((T - model.TC) / model.Ec) ^ 2
    return r < 0 ? zero(r) : r
end

function Rc(T, model::NormalAction)
    return exp(-1/4 * (T - model.TC) ^ 2 / model.Ec)
end

# Forcing model functions using parameters inside AbstractAction structs

function Rf(T, model::BinaryAction)
    return T > model.Tf ? one(T) : zero(T)
end

function Rf(T, model::LinearAction)
    return T > model.Tf ? (T - model.Tf) / model.Ef : zero(T)
end

function Rf(T, model::ExponentialAction)
    return exp(T / model.Tf - 1)
end

function Rf(T, model::SigmoidalAction)
    return 1 / (1 + exp((model.Tf - T) / model.Ef))
end

function Rf(T, model::TriangularAction)
    r = 1 - abs(T - model.Tf) / model.Ef
    return r < 0 ? zero(r) : r
end

function Rf(T, model::ParabolicAction)
    r = 1 - ((T - model.Tf) / model.Ef) ^ 2
    return r < 0 ? zero(r) : r
end

function Rf(T, model::NormalAction)
    return exp(-1/4 * (T - model.Tf) ^ 2 / model.Ef)
end
