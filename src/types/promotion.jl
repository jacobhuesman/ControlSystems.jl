Base.eltype{T}(::Poly{T}) = eltype(T)
Base.eltype{T}(::Type{TransferFunction{T}}) = T
Base.eltype{T}(t::TransferFunction{T}) = T
Base.eltype{T}(::Type{SisoZpk{T}}) = eltype(T)
Base.eltype{T}(t::SisoZpk{T}) = eltype(T)
Base.eltype{T}(::SisoRational{T}) = eltype(T)
Base.eltype{T}(::Type{SisoRational{T}}) = eltype(T)
Base.eltype{T}(::Type{StateSpace{T}}) = T
Base.eltype{T}(t::StateSpace{T}) = T

Base.promote_rule{T, S}(::Type{Poly{T}}, ::Type{Poly{S}}) = Poly{promote_type(T, S)}
Base.promote_rule{S<:TransferFunction{<:SisoTf},T<:Real}(::Type{S}, ::Type{T}) = S
Base.promote_rule{S<:TransferFunction{<:SisoTf},T<:Real}(::Type{S}, ::Union{Type{Array{T,2}},Type{Array{T,1}}}) = S
Base.promote_rule{T <: TransferFunction{<:SisoZpk}}(::Type{<:TransferFunction{<:SisoRational}}, ::Type{T}) = T
Base.promote_rule{T <: TransferFunction{<:SisoGeneralized}}(::Type{<:TransferFunction{<:SisoTf}}, ::Type{T}) = T
Base.promote_rule{T <: SisoZpk}(::Type{<:SisoRational}, ::Type{T}) = T
Base.promote_rule{T <: SisoGeneralized}(::Type{<:SisoTf}, ::Type{T}) = T
Base.promote_rule{T<:SisoZpk}(::Type{T}, ::Type{<:Real}) = T
Base.promote_rule{T<:Real}(::Type{SisoRational}, ::Type{T}) = SisoRational
Base.promote_rule{T1,T2}(::Type{SisoRational{T1}},::Type{SisoRational{T2}}) = SisoRational{promote_type(T1,T2)}
Base.promote_rule{T}(::Type{StateSpace{T}}, ::Type{<:Real}) = StateSpace{T}

for Ty in [StateSpace, TransferFunction, SisoZpk]
    @eval function Base.promote_rule(::Type{T}, ::Type{P})  where T <: $(Ty) where P <: $(Ty)
        $(Ty){promote_type(eltype(T), eltype(P))}
    end
end

function Base.promote_rule(::Type{T}, ::Type{P})  where T <: StateSpace where P <: TransferFunction{<:SisoTf}
    S = promote_type(eltype(eltype(P)), eltype(eltype(T)))
    StateSpace{Matrix{S}}
end


Base.convert{T}(::Type{Poly{T}}, p::Poly) = Poly(convert(T, p.a))
Base.convert{T<:Real}(::Type{<:TransferFunction}, b::T) = tf([b])
Base.convert{T<:Real}(::Type{<:TransferFunction{<:SisoRational}}, b::T) = tf(b)
Base.convert{T<:Real}(::Type{<:TransferFunction{<:SisoZpk}}, b::T) = zpk(b)
Base.convert{T<:Real}(::Type{<:TransferFunction{<:SisoGeneralized}}, b::T) = tfg(b)

Base.convert(::Type{<:TransferFunction{<:SisoZpk}}, s::TransferFunction) = zpk(s)
Base.convert(::Type{<:TransferFunction{<:SisoRational}}, s::TransferFunction) = tf(s)
Base.convert(::Type{<:TransferFunction{<:SisoGeneralized}}, s::TransferFunction) = tfg(s)


function Base.convert{T<:Real}(::Type{<:TransferFunction}, b::VecOrMat{T})
    r = Array{TransferFunction,2}(size(b,2),1)
    for j=1:size(b,2)
        r[j] = vcat(map(k->convert(TransferFunction,k),b[:,j])...)
    end
    hcat(r...)
end

function Base.convert(::Type{<:SisoZpk}, sys::SisoRational)
    if length(sys.num) == 0
        return SisoZpk([],[],0)
    elseif all(sys.den == zero(sys.den))
        error("Zero denominator, this should not be possible")
    else
        return SisoZpk(roots(sys.num),roots(sys.den),sys.num[1]/sys.den[1])
    end
end

function Base.convert(::Type{<:SisoRational}, sys::SisoZpk)
    num = prod(zp2polys(sys.z))*sys.k
    den = prod(zp2polys(sys.p))
    return SisoRational(num, den)
end

Base.convert(::Type{<:SisoGeneralized}, sys::SisoRational) = SisoGeneralized(sprint(print_compact, sys))
Base.convert(::Type{<:SisoGeneralized}, sys::SisoZpk) = convert(SisoGeneralized, convert(SisoRational, sys))
Base.convert(::Type{<:SisoRational}, sys::SisoGeneralized) = SisoRational(sys.expr)
Base.convert(::Type{<:SisoZpk}, sys::SisoGeneralized) = convert(SisoZpk, SisoRational(sys.expr))
Base.convert(::Type{<:ControlSystems.SisoTf}, b::Real) = Base.convert(ControlSystems.SisoRational, b)
Base.convert(::Type{<:SisoZpk}, b::Real) = SisoZpk([], [], b)
Base.convert(::Type{<:SisoRational}, b::Real) = SisoRational([b], [1])
Base.convert{T1}(::Type{SisoRational{Vector{T1}}}, t::SisoRational) =  SisoRational(Poly(T1.(t.num.a)),Poly(T1.(t.den.a)))
Base.convert(::Type{<:StateSpace}, t::Real) = ss(t)

function Base.convert(::Type{<:StateSpace}, t::TransferFunction)
    if !isproper(t)
        error("System is improper, a state-space representation is impossible")
    end
    ny, nu = size(t)
    mat = t.matrix
    # TODO : These are added due to scoped for blocks, but is a hack. This
    # could be much cleaner.
    Ac = Bc = Cc = Dc = A = B = C = D = Array{eltype(mat)}(0, 0)
    for i=1:nu
        for j=1:ny
            a, b, c, d = siso_tf_to_ss(mat[j, i])
            if j > 1
                # vcat
                Ac = blkdiag(Ac, a)
                Bc = vcat(Bc, b)
                Cc = blkdiag(Cc, c)
                Dc = vcat(Dc, d)
            else
                Ac, Bc, Cc, Dc = a, b, c, d
            end
        end
        if i > 1
            # hcat
            A = blkdiag(A, Ac)
            B = blkdiag(B, Bc)
            C = hcat(C, Cc)
            D = hcat(D, Dc)
        else
            A, B, C, D = Ac, Bc, Cc, Dc
        end
    end
    A, B, C = balance_statespace(A, B, C)[1:3]
    return ss(A, B, C, D, t.Ts, inputnames=t.inputnames, outputnames=t.outputnames)
end


Base.zero{T}(p::Poly{T}) = Poly(zeros(eltype(T),1))
Base.zero{T}(::Type{Poly{T}}) = Poly(zeros(eltype(T),1))
Base.one{T}(p::Poly{T}) = Poly(ones(eltype(T),1))
Base.one{T}(::Type{Poly{T}}) = Poly(ones(eltype(T),1))

# Promote_op types
Base.promote_op{T<:SisoTf}(::Any, ::Type{T}, ::Type{T}) = T

#Just default SisoTf to SisoRational
SisoTf(args...) = SisoRational(args...)

Base.zero(::Type{<:SisoTf}) = zero(SisoRational)
Base.zero(::SisoTf) = zero(SisoRational)
Base.zero(::Type{<:SisoZpk}) = SisoZpk([],[],0.0)
Base.zero(::SisoZpk) = Base.zero(SisoZpk)
Base.zero{T}(::Type{SisoRational{T}}) = SisoRational(zero(Poly{T}), one(Poly{T}))
Base.zero{T}(::SisoRational{T}) = Base.zero(SisoRational{T})