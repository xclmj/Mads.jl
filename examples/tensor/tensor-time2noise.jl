import Mads
import NTFk
import JLD
# c = pwd()
# import rMF
# cd(c)

md = Mads.loadmadsfile("w01-tensor2.mads")
Mads.addsource!(md; dict=Dict("t0"=>200., "x"=>1100., "y"=>1450.))
Mads.addsource!(md; dict=Dict("t0"=>400., "x"=>1200., "y"=>1550.))
Mads.plotmadsproblem(md; filename="map.png")
s = size(Mads.forwardgrid(md)[:,:,1])
nstep = 10
T = Array{Float64}(s[2],s[1],nstep);
srand(2017)
for i = 1:nstep
	md["Grid"]["time"] = i * 100
	g = Mads.forwardgrid(md)[:,:,1]
	isnan(g) = minimum(g)
	g[g.>4.e5] = 4.e5
	info("Time: $(md["Grid"]["time"]) Max conc $(maximum(g)) Min conc $(minimum(g))")
	T[:,:,i] = g'
end
JLD.save("tensor2.jld", "T", T)
NTFk.plottensor(T,3)

Mads.createobservations!(md, collect(0:10:1000))
Mads.plotmatches(md; display=true, xmax=1000)

Mads.setobservationtargets!(md, Mads.forward(md))
wt = Mads.getwelltargets(md)
M = hcat(wt...)
M = M./maximum(M)

V = Vector{Matrix{Float64}}(0)
for i = 1:3
	mdo = deepcopy(md)
	for s = 3:-1:1
		if s == i
			continue
		else
			Mads.removesource!(mdo, s)
		end
	end
	warn("Source starting at $(mdo["Sources"][1]["gauss"]["t0"]["init"])")
	Mads.plotmatches(mdo; display=true, xmax=1000)
	Mads.setobservationtargets!(mdo, Mads.forward(mdo))
	wt = Mads.getwelltargets(mdo)
	M = hcat(wt...)
	M = M./maximum(M)
	push!(V, M)
end

nt, nw = size(V[1])
wellnames = ntuple(i->"W$i", nw)
C = reshape(hcat(V...), (nt,nw,3));
W = C ./ maximum(sum(C, 3)) .* 0.9;

# rMF.loaddata("test", ns=3, nc=4, nw=9, nt=101, seed=5)
# Ht = deepcopy(rMF.truebucket)
Hw=[[0,0,1000] [0,1000,0] [1000,0,0] [500,1000,0]]
# B = minimum(Ht,1) .- 4
Hb = [1,1,1,1]
Ht = convert(Array{Float32,2}, [Hw' Hb])'

X = zeros(Float32, nw,4,nt);
Wt = zeros(Float32, nw,4,nt);
for t = 1:nt
	for w = 1:nw
		Wt[w,1:3,t] = W[t,w,:]
		Wt[w,4,t] = 1-sum(W[t,w,:])
		for s = 1:3
			X[w,:,t] += W[t,w,s] * Ht[s,:]
		end
		X[w,:,t] += (1-sum(W[t,w,:])) .* Hb
	end
end

srand(1)
# Xn = X .+ ((randn(size(X)) / 80) .* X)
Xn = convert(Array{Float32,3}, X .+ (randn(size(X)) * 10))
Xn[Xn.<0] .= 0

Mads.plotseries(Xn[:,1,:]')
Mads.plotseries(Xn[:,2,:]')
Mads.plotseries(Xn[:,3,:]')
Mads.plotseries(Xn[:,4,:]')

if isfile("ntfk-contamination-noise.jld")
	Wem, Hem = JLD.load("nmfk-contamination-noise.jld", "We", "He")
else
	Wem, Hem, of, rob, aic = NMFk.execute(Xn[:,:,end], 2:5, 10; quiet=false, mixture=:mixmatch)
	JLD.save("nmfk-contamination-noise.jld", "We", Wem, "He", Hem, "of", of, "rob", rob, "aic", aic)
end
display(X[:,:,end])
display(Wem[4] * Hem[4])

if isfile("ntfk-contamination-noise.jld")
	Wet, Het = JLD.load("ntfk-contamination-noise.jld", "We", "He")
else
	Wet, Het, of, rob, aic = NMFk.execute(Xn, 3:5, 10; maxouteriters=1000, tol=1e-3, tolX=1e-3, tolOF=1., quiet=false)
	JLD.save("ntfk-contamination-noise.jld", "We", Wet, "He", Het, "of", of, "rob", rob, "aic", aic)
end
for i=3:5
	Xe = NMFk.mixmatchcompute(Xn, Wet[i], Het[i])
	info("Norm($i): $(vecnorm(Xe .- Xn))")
end
NTFk.plot2d(permutedims(Wt, (1,3,2))[:,:,:], permutedims(Wet[4], (1,3,2))[:,:,[2,4,3,1]]; xtitle="", ytitle="", wellnames=wellnames, keyword="noise-signals", xmax=100, ymax=1., gm=[Gadfly.Guide.manual_color_key("Sources", ["S1", "S2", "S3", "Background"], NTFk.colors[1:4]), Gadfly.Theme(major_label_font_size=16Gadfly.pt, key_label_font_size=14Gadfly.pt, minor_label_font_size=12Gadfly.pt)])
display(Ht)
display(Het[4][[2,3,1,4],:])

Xe = NMFk.mixmatchcompute(Xn, Wet[4], Het[4])
NTFk.plot2d(permutedims(Xn, (1,3,2))/1000, permutedims(Xe, (1,3,2))/1000; xtitle="", ytitle="", wellnames=wellnames, keyword="noise-species", xmax=100, ymin=0, ymax=1., gm=[Gadfly.Guide.manual_color_key("Species", ["A", "B", "C", "D"], NTFk.colors[1:4]), Gadfly.Theme(major_label_font_size=16Gadfly.pt, key_label_font_size=14Gadfly.pt, minor_label_font_size=12Gadfly.pt)])