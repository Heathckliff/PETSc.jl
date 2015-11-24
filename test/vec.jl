
# create Vec
facts("\n --- Testing Vector Function ---") do
vtype = PETSc.C.VECMPI
vec = PETSc.Vec(ST, vtype)
#PETSc.settype!(vec, vtype)
resize!(vec, 4)
@fact_throws resize!(vec)
len_ret = length(vec)

@fact length(vec) --> 4
@fact size(vec) --> (4,)
@fact lengthlocal(vec) --> 4
@fact sizelocal(vec) --> (4,)

@fact PETSc.gettype(vec) --> PETSc.C.VECMPI

println("point 1")

vt = complex(2.,2)  # use vt to hold temporary values
vec[1] = RC(vt)
val_ret = vec[1]
@fact vec[1] --> RC(vt)

vec2 = similar(vec,ST)
PETSc.AssemblyBegin(vec2)
PETSc.AssemblyEnd(vec2)
val2_ret = vec2[1]

@fact val2_ret --> not(val_ret)

if gettype(vec2) == PETSc.C.VECSEQ
  lv2 = localpart(vec2)
  for i in 1:length(lv2)
      @fact lv2[i] --> vec2[i]
  end
end

vec3 = similar(vec, ST, 5)
@fact length(vec3) --> 5

println("\n\n\n Copying vec to vec4")
vec4 = copy(vec)
println("vec = ", vec)
println("vec4 = ", vec4)

println("\n\n\n")
for i=eachindex(vec)
  @fact vec4[i] --> roughly(vec[i])
end

println("point 2")

idx = [1,3, 4]
vt = RC(complex(2.,2))
println("idx = ",idx)
println("typeof(idx) = ", typeof(idx))
println("size(vec4) = ", size(vec4))
vec4[idx] = vt
println("set vec4 values")
println("idx = ", idx)
println("size(vec4) = ", size(vec4))
vals_ret = vec4[idx]
println("retrieved vec4 values")
println("vals_ret = ", vals_ret)
println("point 2.4")
println("idx = ", idx)
println("typeof(idx) = ", typeof(idx))
println("length(idx) = ", length(idx))
for i=1:length(idx)
  println("i = ", i)
  @fact vals_ret[i] --> vt
end

println("point 2.5")
vt = RC(complex(3.,3))
fill!(vec4, vt)

for i=eachindex(vec4)
  @fact vec4[i] --> roughly(vt)
end

vt = RC(complex( 4.,4))
vec4[1:2] = vt

println("point 3")
@fact vec4[1:2] --> [vt, vt]

vals = [RC(complex(1,1.)), RC(complex(3.,3)), RC(complex(4., 3))]
vec4[idx] = vals

for i=eachindex(idx)
  @fact vec4[idx[i]] --> vals[i]
end


println("testing logical indexing")
logicals = Array(Bool, length(vec4))
for i=eachindex(logicals)
  logicals[i] = false
end
logicals[2] = true

vt = RC(complex(5,5.))
vec4[logicals] = vt

@fact vec4[2] --> roughly(vt)
@fact vec4[1] --> not(vt)

vt = RC(complex(rand(), rand()))
vals = [vt]
vec4[logicals] = vals
println("vals = ", vals)
println("logicals = ", logicals)
println("vec4 = ", vec4)
@fact vec4[2] --> roughly(vals[1])
@fact vec4[1] --> not(vals[1])

# reset vec4
vec4_j = zeros(ST, length(vec4))
for i=1:length(vec4)
  vec4[i] = RC(complex(Float64(-i), Float64(-i)))
  vec4_j[i] = RC(complex(Float64(-i), Float64(-i)))
end

println("testing math functions")

println("testing abs")
vec4_j = abs(vec4_j)
absv4  = abs(vec4)
abs!(vec4)

for i=eachindex(vec4)
  @fact vec4[i] --> vec4_j[i]
  @fact absv4[i] --> vec4_j[i]
end

println("testing exp")

println("before, vec and vec4 = ")
println("vec4 = ", vec4)
println("vec4_j = ", vec4_j)

vec4_j = exp(vec4_j)
exp!(vec4)

println("vec4 = ", vec4)
println("vec4_j = ", vec4_j)

for i=eachindex(vec4)
  @fact vec4[i] --> roughly(vec4_j[i], atol=1e-4)
end

println("testing log")
vec4_j = log(vec4_j)
log!(vec4)

for i=eachindex(vec4)
  @fact vec4[i] --> roughly(vec4_j[i], atol=1e-4)
end

println("testing norm")
onevec = PETSc.Vec(ST, vtype)
resize!(onevec, 4)
PETSc.AssemblyBegin(onevec)
PETSc.AssemblyEnd(onevec)
for i=1:length(onevec)
    onevec[i] = one(ST)
end
println("onevec: ",onevec)

@fact_throws ArgumentError norm(onevec,3)
@fact norm(onevec,Inf) --> 1
normvec = copy(onevec)
PETSc.normalize!(normvec)
@fact norm(normvec,2) --> one(ST)

if ST <: Real
    println("testing max and min")
    maxvec = copy(onevec)
    maxvec[1] = ST(2)
    @fact maximum(maxvec) --> 2
    @fact findmax(maxvec) --> (2.0,1)
    minvec = copy(onevec)
    minvec[1] = ST(0)
    @fact minimum(minvec) --> 0
    @fact findmin(minvec) --> (0.0,1)
end

println("testing pointwise max, min, /")
div1vec = 2*copy(onevec)
div2vec = 4*copy(onevec)
@fact max(div1vec,div2vec) == div2vec --> true
@fact min(div1vec,div2vec) == div1vec --> true
@fact div1vec .* div2vec == 8*onevec --> true
@fact div2vec ./ div1vec == div1vec --> true

println("testing scale!")
scalevec = scale!(copy(onevec),2)
for i=1:length(onevec)
    @fact scalevec[i] --> 2
end

println("testing sum")
@fact sum(onevec) --> length(onevec)

println("testing negation")
minusvec = -onevec
for i=1:length(onevec)
    @fact minusvec[i] --> -onevec[i]
end

println("testing * and /")
multvec = copy(onevec)
multvec = multvec * 2 * 3 * 4
for i=1:length(onevec)
    @fact multvec[i] --> 24*onevec[i]
end
multvec = copy(onevec)
multvec = 2 .* multvec
for i=1:length(onevec)
    @fact multvec[i] --> 2*onevec[i]
end
divvec = copy(onevec)
divvec = divvec * 2 * 3
divvec = divvec ./ 2
for i=1:length(onevec)
    @fact divvec[i] --> 3*onevec[i]
end
divvec = 3 .\ divvec
for i=1:length(onevec)
    @fact divvec[i] --> onevec[i]
end

divvec = 2*copy(onevec)
divvec = 2 ./ divvec
for i=1:length(onevec)
    @fact divvec[i] --> onevec[i]
end

addvec = copy(onevec)
println("testing ==")
@fact addvec == onevec --> true
println("testing + and -")
addvec = addvec + 2
addvec = addvec - 2
for i=1:length(onevec)
    @fact addvec[i] --> onevec[i]
end
addvec = copy(onevec)
addvec = 2 - addvec
addvec = 2 + addvec
for i=1:length(onevec)
    @fact addvec[i] --> 3*onevec[i]
end

#=
val = norm(vec4, 1)
val_j = norm(vec4_j, 1)

@fact val --> val_j

val = norm(vec4, 2)
val_j = norm(vec4_j, 2)

@fact val --> val_j

val = norm(vec4, Inf)
val_j = norm(vec4_j, Inf)

@fact val --> val_j
=#
#=
normalize!(vec4)
vec4_j = vec4_j/norm(vec4_j, 2)

for i=1:length(vec4)
  @fact vec4[i] --> vec4_j[i]
end
=#

println("testing dot product")

val = dot(vec4, vec)
#val_j = vec4.'*vec
val_j = dot(vec4, vec)
println("val = ", val)
println("val_j = ", val_j)

@fact val --> val_j

# make copies of vecs 1 2 4

println("testing level 1 Blas")

vecj = zeros(ST, length(vec))
vec2j = zeros(ST, length(vec))
vec4j = zeros(ST, length(vec))

for i=1:length(vec)
  vecj[i] = vec[i]
  vec2j[i] = vec2[i]
  vec4j[i] = vec4[i]
end

println("testing axpy")
vt = RC(complex(2.,2))
axpy!(vt, vec, vec2)
vec2j = vt*vecj + vec2j
println("vec2j = ", vec2j)
println("vec2 = ", vec2)
for i=1:length(vec)
  println("vec2j[i] = ", vec2j[i], ", vec2[i] = ", vec2[i])
  @fact vec2j[i] --> vec2[i]
end

println("testing 4 argument axpy")
axpy!(vt, vec, vec2, vec4)
vec4j = vt*vecj + vec2j

for i=eachindex(vec2)
  @fact vec2j[i] --> vec2[i]
end

println("testing aypx")
aypx!(vec, vt, vec2)
vec2j = vt*vec2j + vec

for i=eachindex(vec)
  @fact vec2j[i] --> vec2[i]
end

println("testing axpby")
println("before operation:")
println("vec = ", vec)
println("vecj = ", vecj)
println("vec2 = ", vec2)
println("vec2j = ", vec2j)

vt2 = RC(complex(3.,3))
vt3 = RC(complex(4.,4))
axpby!(vt, vec, vt2, vec2)
vec2j = vt*vecj + vt2*vec2j
println("after operation:")
println("vec = ", vec)
println("vecj = ", vecj)
println("vec2 = ", vec2)
println("vec2j = ", vec2j)
for i=eachindex(vec)
  @fact vec2j[i] --> vec2[i]
end

axpbypcz!(vt, vec, vt2, vec2, vt3, vec4)
vec4j = vt*vecj + vt2*vec2j + vt3*vec4j

for i=eachindex(vec)
  @fact vec4j[i] --> vec4[i]
end

vecs = Array(typeof(vec), 2)
vecs[1] = vec
vecs[2] = vec2
#vecs = [vec; vec2]
alphas = [vt2, vt3]
println("vecs = ", vecs)
println("typeof(vecs) = ", typeof(vecs))

axpy!(vec4, alphas, vecs)
vec4j = vec4j + vt2*vecj + vt3*vec2j
println("vec4 = ", vec4)
println("vec4j = ", vec4j)
for i=eachindex(vec)
  @fact vec4j[i] --> vec4[i]
end


vec5 = Vec(ST, 3, PETSc.C.VECMPI)
vec6 = similar(vec5)
vec5j = zeros(ST, 3)
vec6j = zeros(ST, 3)

for i=1:3
  i_float = Float64(i)

  vec5[i] = RC(complex(i_float, i_float))
  vec6[i] = RC(complex(i_float+3, i_float+3))
  vec5j[i] = RC(complex(i_float, i_float))
  vec6j[i] = RC(complex(i_float +3, i_float+3))
end

println("vec5 = ", vec5)
println("vec6 = ", vec6)

vec7 = vec5.*vec6
vec7j = vec5j.*vec6j
println("vec7j = ", vec7j)
println("vec7 = ", vec7)
for i=1:3
  @fact vec7[i] --> roughly(vec7j[i])
end

vec8 = vec5./vec6
vec8j = vec5j./vec6j

for i=1:3
  @fact vec8[i] --> roughly(vec8j[i])
end

vec9 = vec5.^3
vec9j = vec5j.^3

for i=1:3
  @fact vec9[i] --> roughly(vec9j[i])
end

vec10 = vec5 + vec6
vec10j = vec5j + vec6j
for i=1:3
  @fact vec10[i] --> roughly(vec10j[i])
end

vec11 = vec5 - vec6
vec11j = vec5j - vec6j

for i=1:3
  @fact vec11[i] --> roughly(vec11j[i])
end

context("test unconjugated dot product") do
    x = Vec(ST, 2)
    y = Vec(ST, 2)
    copy!(y, [1, 1])
    if ST <: Complex
        copy!(x, [1, im])
        @fact (x'*y)[1] --> 1-im
        @fact (x.'*y)[1] --> 1+im
    else
        copy!(x, [2, 3])
        @fact (x'*y)[1] --> 5
        @fact (x.'*y)[1] --> 5
    end
end

let x = rand(ST, 7)
  @fact Vec(x) --> x
end

end
