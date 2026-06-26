module state

//|-----------------------------------------------|//
//|  State effect mimicing Haskell's State Monad  |//
//|-----------------------------------------------|//

pub effect state<s>
  fun get() : s
  fun put(s : s) : ()

pub fun state(s, action)
  var st := s
  with handler
    fun get()   st
    fun put(s') st := s'
    return(x)   (x, st)
  action()

pub fun modify(f)
  val s = get()
  put(f(s))

pub fun gets(f)
  f(get())

struct person
  name : string
  age : int

fun person/show(Person(nm, ag))
  "Person(name="++nm++", age="++ag.show++")"

fun cek-gets()
  val nm = gets(name)
  nm.to-upper.println
