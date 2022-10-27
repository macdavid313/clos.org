+++
title = "Embedding Julia in Lisp"
date = 2017-03-19
tags = ["lisp", "julia"]
+++

Julia is a high-level dynamic programming language designed to address the needs of high-performance numerical analysis and computational science while also being effective for general-purpose programming, web use or as a specification language[^1]. I like its Lisp-like macros and [multiple dispatch](https://en.wikipedia.org/wiki/Multiple_dispatch) strategy. After all, it’s from MIT, where LISP happens. Its performance, according to this [paper](http://julialang.org/images/julia-dynamic-2012-tr.pdf), is often within a factor of two relative to fully optimized C code (and thus often an order of magnitude faster than Python or R)[^2]. Besides macros (or other meta-programming facilities), multiple dispatch and high performance. Julia can call Python (by using PyCall[^3] package) and C functions (without wrappers). This support may be very important for a new community programming language.

Anyway, Julia looks very promising. Since most Lisp has a bad (and somewhat unfair at all) reputation for performance, I’m thinking about one can embed Julia into Lisp systems and make it like an agent for numerical computation tasks. Common Lisp community already has a package called `burgled-batteries`, by using which people can calling Python 2.7[^4] functions, massive libraries and functionalities become available for Common Lisp, therefore.

But after I tried to embed Julia in SBCL, unfortunately, memory errors took place. Here is a session on Ubuntu 16.04:

```lisp
david@ubuntu-512mb-fra1-01:~/julia$ sbcl --load ~/quicklisp/setup.lisp
This is SBCL 1.3.15.10-1c20666, an implementation of ANSI Common Lisp.
More information about SBCL is available at <http://www.sbcl.org/>.

SBCL is free software, provided as is, with absolutely no warranty.
It is mostly in the public domain; some portions are provided under
BSD-style licenses.  See the CREDITS and COPYING files in the
distribution for more information.
* (ql:quickload :cffi)
To load "cffi":
  Load 1 ASDF system:
    cffi
; Loading "cffi"
.
(:CFFI)
* (cffi:load-foreign-library "/home/david/julia/lib/libjulia.so")

#<CFFI:FOREIGN-LIBRARY LIBJULIA.SO-483 "libjulia.so">
* (cffi:defcfun ("jl_init" jl-init) :void (julia-home-dir :string))

JL-INIT
* (jl-init "/home/david/julia/lib")

* (cffi:defcfun ("jl_eval_string" jl-eval-string) :pointer (str :string))
fatal: error thrown and no exception handler available.
ReadOnlyMemoryError()
unknown function (ip: 0x21ba66dd)
unknown function (ip: 0x21b8a105)
unknown function (ip: 0x21ba62c6)
unknown function (ip: 0x21ba6046)
unknown function (ip: 0x21ba5be1)
unknown function (ip: 0x21ba58af)
unknown function (ip: 0x21ba55bc)
unknown function (ip: 0x21ba5488)
unknown function (ip: 0x21b320e2)
unknown function (ip: 0x21b69702)
unknown function (ip: 0x21b3aead)
unknown function (ip: 0x21b3a3a7)
unknown function (ip: 0x21b3a3a7)
unknown function (ip: 0x21b39621)
unknown function (ip: 0x21dd95f3)
unknown function (ip: 0x22245a59)
unknown function (ip: 0x21e138e9)
unknown function (ip: 0x21e7b711)
unknown function (ip: 0x21e13505)
unknown function (ip: 0x21e12dac)
unknown function (ip: 0x2253592a)
unknown function (ip: 0x2253563e)
call_into_lisp at sbcl (unknown line)
```

This process failed on CCL as well, but ECL survived so far, which makes this bug more confusing. While I think it’s an internal error in Lisp implementations, @开源哥 suggested it might come from Julia side.

However, on the other hand, things work pretty well on Chez Scheme:

```scheme
(define *julia-root-path* "/home/david/julia/")

(define *julia-lib-path*
  (string-append *julia-root-path* "lib/"))

(define *libjulia*
  (string-append *julia-lib-path* "libjulia.so"))

(define jl-init
  (foreign-procedure "jl_init" (string) void*))

(define jl-eval-string
  (foreign-procedure "jl_eval_string" (string) void*))

(define jl-unbox-float64
  (foreign-procedure "jl_unbox_float64" (void*) double-float))

(load-shared-object *libjulia*)
(jl-init *julia-lib-path*)

(jl-eval-string "sqrt(2.0)")
;; => 4694870240

(jl-unbox-float64 (jl-eval-string "sqrt(2.0)"))
;; => 1.4142135623730951
```

On Julia’s documentation page, there’s one [chapter](https://docs.julialang.org/en/v1/manual/embedding/) talking about embedding specifically, where these topics are outlined:

1. Loading dynamic library and initializing Julia runtime
2. Converting Types
3. Calling Julia Functions
4. Memory Management and GC
5. Arrays
6. Exceptions

You will find it will be easier to embed Julia than e.g. CPython into Lisp or any other system, especially for the memory management part, where CPython uses `reference counting` which is somewhat painful for maintaining. If one can solve the problem shown before on SBCL and CCL, Common Lisp community may have another package calling Julia functions in the future. So if anyone knows how to deal with it, please tell me or just fix it and implement the package “in one breath”.

[^1]: Wikipedia, Julia (programming language), [https://en.wikipedia.org/wiki/Julia_(programming_language)](https://en.wikipedia.org/wiki/Julia_(programming_language))
[^2]: Jeff Bezanson, Stefan Karpinski, Viral B. Shah, Alan Edelman, [Julia: A Fast Dynamic Language for Technical Computing](https://arxiv.org/abs/1209.5145), 2012.
[^3]: [“Smoothing data with Julia’s @generated functions”](https://medium.com/@acidflask/smoothing-data-with-julia-s-generated-functions-c80e240e05f3#.615wk3dle). 5 November 2015. Retrieved 9 December 2015. “Julia’s generated functions are closely related to the multistaged programming (MSP) paradigm popularized by Taha and Sheard, which generalizes the compile time/run time stages of program execution by allowing for multiple stages of delayed code execution.”
[^4]: Note: Python 3.x might be available as well, please see this [pull request](https://github.com/pinterface/burgled-batteries/pull/8) on Github.