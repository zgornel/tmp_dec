# Functionality module 
module Radix
	import Base: show
	include("foo.jl")
	include("bar.jl")
	include("baz.jl")
	include("goo.jl")
	include("observer.jl")
	export foo, bar, baz, goo, Observer, fhash!, ftrack!, iomap!, deps!, wrapped_execution!,f_symbol,
		decorate, load_observer, store_observer
end


# Test module
module Test

	using Radix
	import Radix: baz

	ob = Observer()		# pipeline observer object
	obfile = "ob.bin"	# file where the observer resides
	ifile = "input.dat"	# Input file 
	ifile2 = "input2.dat"	# Second input file
				
	#############			
	# Quick hack. 		/-----------------\/	
	# Pipeline is: input-->foo-->bar-->baz-->goo-->output	
	#############		     \------------/\

	# Define function to dependent functions mapping
	dp = Dict(:foo=>Symbol[:bar, :goo],
	     		:bar=>[:baz, :goo],
			:baz=>[:goo],
			:goo=>Symbol[]
		)

	# Define function=>file mapping
	ft = Dict(k=>String(k)*".jl" for k in keys(dp))

	# Initialize and store observer
	deps!(ob,dp)
	ftrack!(ob,ft)
	
	# Decorate pipeline functions
	_foo,_bar, _baz, _goo = decorate(ob,foo,bar,baz,goo)


	# Burn-in of the functions (store hashes, i/o maps)
	##############################
	println("\nBURNIN run\n============")
	input = String.(chop(readstring(ifile)))
	println("INPUT = $input")
	result = input |> _foo |> _bar |> _baz 
	result =  _goo(_foo(input), result, _bar(_foo(input))) 
	println("OUTPUT = $(result)")
	
	store_observer(ob, obfile)
	# @show ob



	# Run 1: same pipeline, same inputs 
	###########
	result = []
	ob = load_observer(obfile)
	_foo,_bar, _baz, _goo = decorate(ob,foo,bar,baz,goo)
	
	println("\nRUN 1:  same pipeline, no change\n============")
	ifile = "input.dat"
	input = String.(chop(readstring(ifile)))
	println("INPUT = $input")
	result = input |> _foo |> _bar |> _baz 
	result =  _goo(_foo(input), result, _bar(_foo(input))) 
	println("OUTPUT = $(result)")


	# Run 2: same pipeline, different inputs 
	###########
	result = []
	ob = load_observer(obfile)
	_foo,_bar, _baz, _goo = decorate(ob,foo,bar,baz,goo)

	println("\nRUN 2:  same pipeline, different inputs\n============")
	ifile = "input2.dat"
	input = String.(chop(readstring(ifile)))
	println("INPUT = $input")
	result = input |> _foo |> _bar |> _baz 
	result =  _goo(_foo(input), result, _bar(_foo(input))) 
	println("OUTPUT = $(result)")

	store_observer(ob, obfile)


	# Run 3: same pipeline, file modified (baz.jl)
	###########
	result = []
	ob = load_observer(obfile)

	# create new baz function, evaluate it and write it to modify baz.jl
	strbaz = readstring("baz.jl");
	newbaz = replace(strbaz,"rn \"baz(","rn \"BAZ(") # returns "BAZ(input)"
	open("baz.jl","w") do x
		write(x, newbaz);
	end
	# Load the new baz()
	eval(parse(newbaz))
	
	# Re-decorate
	_foo,_bar, _baz, _goo = decorate(ob,foo,bar,baz,goo)
	
	println("\nRUN 3:  same pipeline, baz.jl modified (baz() and goo() impacted)\n============")
	ifile = "input.dat"
	input = String.(chop(readstring(ifile)))
	println("INPUT = $input")
	result = input |> _foo |> _bar |> _baz 
	result =  _goo(_foo(input), result, _bar(_foo(input))) 
	println("OUTPUT =$(result)")
	
	# revert baz.jl
	open("baz.jl","w") do x
		write(x, strbaz)
	end

end
