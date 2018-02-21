function baz(input::String)
	println("`-In baz. Processing...")
	sleep(1)
	return "baz($(input))"
end
