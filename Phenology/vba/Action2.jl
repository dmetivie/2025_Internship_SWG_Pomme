# DScine a generic AbstractAction abstract type
"""
# Example for chilling model
    chill_model = LinearAction(10.0, 5.0)  # Th = 10, Sc = 5
    T = 7.0
    Rc(T, chill_model)  # Should return (10 - 7) / 5 = 0.6

# Example for forcing model
    force_model = SigmoidalAction(15.0, 3.0)  # Th = 15, Sc = 3
    T = 18.0
    Rf(T, force_model)  # Should return a value based on the sigmoidal equation
"""
abstract type AbstractAction end

# Concrete types for models with their parameters

struct BinaryAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
end

struct LinearAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct ExponentialAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
end

struct SigmoidalAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct TriangularAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct ParabolicAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct NormalAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

# Chilling model functions using parameters inside AbstractAction structs

function Rc(T, model::BinaryAction)
    return T < model.Th ? one(T) : zero(T)
end

function Rc(T, model::LinearAction)
    return T < model.Th ? (model.Th - T) / model.Sc : zero(T)
end

function Rc(T, model::ExponentialAction)
    return exp(-T / model.Th)
end

function Rc(T, model::SigmoidalAction)
    return 1 / (1 + exp((T - model.Th) / model.Sc))
end

function Rc(T, model::TriangularAction)
    r = 1 - abs(T - model.Th) / model.Sc
    return r < 0 ? zero(r) : r
end

function Rc(T, model::ParabolicAction)
    r = 1 - ((T - model.Th) / model.Sc) ^ 2
    return r < 0 ? zero(r) : r
end

function Rc(T, model::NormalAction)
    return exp(-1/4 * (T - model.Th) ^ 2 / model.Sc)
end

# Forcing model functions using parameters inside AbstractAction structs

function Rf(T, model::BinaryAction)
    return T > model.Th ? one(T) : zero(T)
end

function Rf(T, model::LinearAction)
    return T > model.Th ? (T - model.Th) / model.Sc : zero(T)
end

function Rf(T, model::ExponentialAction)
    return exp(T / model.Th - 1)
end

function Rf(T, model::SigmoidalAction)
    return 1 / (1 + exp((model.Th - T) / model.Sc))
end

function Rf(T, model::TriangularAction)
    r = 1 - abs(T - model.Th) / model.Sc
    return r < 0 ? zero(r) : r
end

function Rf(T, model::ParabolicAction)
    r = 1 - ((T - model.Th) / model.Sc) ^ 2
    return r < 0 ? zero(r) : r
end

function Rf(T, model::NormalAction)
    return exp(-1/4 * (T - model.Th) ^ 2 / model.Sc)
end