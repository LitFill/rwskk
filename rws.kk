module rws

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

pub fun greet()
  val name = ask ()
  val p = print
  "Hello, ".p; name.p; "!".println

pub fun sq()
  val h = asks fn(r) r * r
  h.show

//|-------------------------------------------------|//
//|  Writer effect mimicing Haskell's Writer Monad  |//
//|-------------------------------------------------|//

pub effect writer<w>
  fun tell(w : w) : ()

pub fun writer(action, ?show)
  var ws := []
  with handler
    fun tell(w)
      ws := Cons(w, ws)
    return(x)
      (x, ws.reverse.map(?show).concat/join)
  action()

pub fun listen(action, ?show)
  with writer
  action()

pub fun pass(action)
  val (x, f) = action ()
  tell(f(w))
  x


fun writing-length(xs)
  fun go(ys, acc)
    match ys
      Nil -> acc
      Cons(y, yy) -> 
        tell(y)
        go(yy, acc + 1)
  go(xs, 0)

pub fun len-write()
  val xs = [1, 2, 3, 4, 5]
  with writer
  xs.writing-length

//|---------------------|//
//|  Using RWS effects  |//
//|---------------------|//

pub fun rws ()
  "from rws".println
  with reader("LitFill")
  greet ()
  local (to-upper)
    greet()
  local fn(r) { 67.show }
    greet()
  greet ()
