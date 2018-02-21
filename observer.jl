mutable struct Observer
	ftrack::Dict{Symbol, String} 		# file tracker function=>file
	fhash::Dict{Symbol, UInt64}		# file hash function=>hash(file)
	iomap::Dict{Symbol, Dict{Tuple, Any}}	# I/O map input=>output
	deps::Dict{Symbol, Vector{Symbol}}	# dependencies function=>list of impacted functions
	exec::Dict{Symbol,Bool}			# execution function=>execution_flag
end
Observer() = Observer(Dict{Symbol, String}(),
		      Dict{Symbol, UInt32}(), 
		      Dict{Symbol, Dict{Tuple, Any}}(), 
		      Dict{Symbol, Vector{Symbol}}(),
		      Dict{Symbol, Bool}())

Base.show(io::IO, ob::Observer) = begin 
	println(io, "An observer, $(length(keys(ob.deps))) functions.")
	for k in keys(ob.deps)
		println(io,"`-$k: hash=$(get(ob.fhash,k,nothing)), deps=$(get(ob.deps,k,nothing)),",
	  		"exec=$(get(ob.exec, k, nothing))")
	end
end

ftrack!(ob::Observer, ft::Dict{Symbol, String}) = begin
	ob.ftrack = ft
	return ob
end

fhash!(ob::Observer, fh::Dict{Symbol, UInt32}) = begin
	ob.fhash = fh
	return ob
end

iomap!(ob::Observer, iom::Dict{Symbol, Dict{Tuple, Any}}) = begin
	ob.iomap = iom
	return ob
end

deps!(ob::Observer, dp::Dict{Symbol, Vector{Symbol}}) = begin
	ob.deps = dp
	for k in keys(dp)
		push!(ob.iomap, k=>Dict{Tuple,Any}())
	end
	return ob
end

function wrapped_execution!(ob::Observer, f::Function, f_args::Tuple)
	fs = f_symbol(f)			# function symbol
	fh = hash(readstring(ob.ftrack[fs]))	# function hash
	
	if get(ob.fhash, fs, 0) != fh
		# f never seen before or was modified
		println("-->$fs is executed!")
		push!(ob.fhash, fs=>fh)
		push!(ob.exec, fs=>true)
		
		for v in ob.deps[fs]
			push!(ob.exec, v=>true)
		end
	else
		# f was seen or was not modified
		if ob.exec[fs]
			# f is to be executed (upstream modification)
		else
			if f_args in keys(ob.iomap[fs])
				push!(ob.exec, fs=>false)
			else
				push!(ob.exec, fs=>true)
				
				for v in ob.deps[fs]
					push!(ob.exec, v=>true)
				end
			end	
		end 
	end 

	if ob.exec[fs] 
		result = f(f_args...)
		push!(ob.iomap[fs], f_args=>result)
		push!(ob.exec, fs=>false)
		return result
	else
		println("-->$fs is skipped!")
		return ob.iomap[fs][f_args] 
	end
end

f_symbol(f::Function) = Symbol(split(String(Symbol(f)),".")[end])

# define decorator-like object
function observe(ob::Observer, f::Function)
	return (args...)-> wrapped_execution!(ob, f, args)
end

decorate(ob::Observer, args...) = Tuple(observe(ob,arg) for arg in args)

function load_observer(obfile::String)
	ob = open(obfile,"r") do fid
		deserialize(fid)
	end
end

function store_observer(ob::Observer, obfile::String)
	open(obfile,"w") do fid 
		serialize(fid,ob)
	end
end
