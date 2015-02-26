function madsforwardrun(parameters::Dict)
	f(t) = parameters["a"] * t - parameters["b"]
	times = 1:4
	predictions = Dict{String, Float64}(map(i -> string("v", i), times), map(f, times))
	return predictions
end
