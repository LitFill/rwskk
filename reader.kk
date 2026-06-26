module reader

//|-------------------------------------------------|//
//|  Reader effect mimicing Haskell's Reader Monad  |//
//|-------------------------------------------------|//

pub effect reader<a>
  fun ask() : a

pub fun reader(a, action)
  with fun ask() a
  action()

pub fun asks(f)
  val r = ask()
  f(r)

pub fun local(f, action)
  val r = ask()
  with reader(asks(f))
  action()

//|-----------------------|//
//|  Using Reader effect  |//
//|-----------------------|//

fun greet()
  val name = ask ()
  val p = print
  "Hello, ".p; name.p; "!".println

fun sq()
  val h = asks fn(r) r * r
  h.show

