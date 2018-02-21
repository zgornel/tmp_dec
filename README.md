## Naive test for pipeline decoration

- Four functions available: `foo`, `bar`, `baz`, `goo`, each taking as input a string and returning `"function_name(input)"`. For example, 
`bar("x") == "bar(x)".

- Pipeline of the form:
```julia		
#         /-----------------\/ 
#input-->foo-->bar-->baz-->goo-->output
#              \------------/\
```

Running the main file (`top.jl`) results in:

```julia
BURNIN run
============
INPUT = *
-->foo is executed!
`-In foo. Processing...
-->bar is executed!
`-In bar. Processing...
-->baz is executed!
`-In baz. Processing...
-->foo is skipped!
-->foo is skipped!
-->bar is skipped!
-->goo is executed!
`-In goo. Processing...
OUTPUT = goo(foo(*),baz(bar(foo(*))),bar(foo(*)))

RUN 1:  same pipeline, no change
============
INPUT = *
-->foo is skipped!
-->bar is skipped!
-->baz is skipped!
-->foo is skipped!
-->foo is skipped!
-->bar is skipped!
-->goo is skipped!
OUTPUT = goo(foo(*),baz(bar(foo(*))),bar(foo(*)))

RUN 2:  same pipeline, different inputs
============
INPUT = **
`-In foo. Processing...
`-In bar. Processing...
`-In baz. Processing...
-->foo is skipped!
-->foo is skipped!
-->bar is skipped!
`-In goo. Processing...
OUTPUT = goo(foo(**),baz(bar(foo(**))),bar(foo(**)))

RUN 3:  same pipeline, baz.jl modified (baz() and goo() impacted)
============
INPUT = *
-->foo is skipped!
-->bar is skipped!
-->baz is executed!
`-In baz. Processing...
-->foo is skipped!
-->foo is skipped!
-->bar is skipped!
`-In goo. Processing...
OUTPUT =goo(foo(*),BAZ(bar(foo(*))),bar(foo(*)))
```
