"Make MADS quiet"
function quieton()
	global quiet = true;
end

"Make MADS not quiet"
function quietoff()
	global quiet = false;
end

function create_tests_on()
	global create_tests = true;
end

function create_tests_off()
	global create_tests = false;
end

"Set MADS debug level"
function setdebuglevel(level::Int)
	global debuglevel = level
end

"Set MADS verbosity level"
function setverbositylevel(level::Int)
	global verbositylevel = level
end

"Reset the model runs count"
function resetmodelruns()
	global modelruns = 0
end

"Check for a Mads keyword"
function haskeyword(madsdata::Associative, keyword::AbstractString)
	return haskey(madsdata, "Problem") ? haskeyword(madsdata, "Problem", keyword) : false
end

"Check for a Mads keyword in a Mads class"
function haskeyword(madsdata::Associative, class::AbstractString, keyword::AbstractString)
	return haskey(madsdata[class], keyword) ? true : false
end