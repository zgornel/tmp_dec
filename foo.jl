function foo(input::String)
	println("`-In foo. Processing...")
	sleep(1)
	return "foo($(input))"
end
