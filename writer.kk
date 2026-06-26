module writer

//|----------|//
//|  Monoid  |//
//|----------|//

pub struct monoid<m>
  append : (x : m, y : m) -> m
  empty : m

pub fun ?string/monoid() : monoid<string>
  Monoid((++), "")

pub fun ?list/monoid() : monoid<list<a>>
  Monoid((++), [])

pub fun make/monoid(?append, ?empty)
  Monoid(?append, ?empty)

//|-------------------------------------------------|//
//|  Writer effect mimicing Haskell's Writer Monad  |//
//|-------------------------------------------------|//

pub effect writer<w>
  fun tell(w : w) : ()

pub fun writer(action : () -> <writer<w>|e> a, ?monoid : monoid<w>) : e (a, w)
  var ws := monoid.empty
  with handler
    fun tell(w)
      ws := (monoid.append)(ws, w)
    return(x)
      (x, ws)
  action()

pub fun listen(action, ?monoid)
  writer(action)

pub fun listens(f, action, ?monoid)
  val (x, w) = writer(action)
  (x, f(w))

pub fun pass(action, ?monoid)
  val ((x, f), w) = writer(action)
  tell(f(w))
  x

pub fun censor(f, action, ?monoid)
  val (x, w) = action.writer
  tell(f(w))
  x

//|-----------------------|//
//|  Using Writer effect  |//
//|-----------------------|//

fun cek-listens()
  val empty = ""
  val append = fn(x, y) x ++ "\n" ++ y
  val monoid = make/monoid()
  listens(to-upper)
    writing-length("Hello, Writer effect!".split(" "))

fun cek-pass()
  val monoid = string/monoid()
  with writer
  writing-length(["a", "b"])
  val b = pass
      tell("inside pass")
      ("x", to-upper)
  tell("after pass")
  b

fun cek-censor()
  val monoid = string/monoid()
  with writer
  writing-length(["a", "b"])
  val b =
    with censor() fn(w)
      string/repeat("*", w.chars/count)
    tell("pass")
    "x"
  tell("after censor")
  b

fun writing-length(xs)
  fun go(ys, acc)
    match ys
      Nil -> acc
      Cons(y, yy) ->
        tell(y)
        go(yy, acc + 1)
  go(xs, 0)

fun www(monoid, action)
  with writer
  action()

fun writer-string(action)
  with www(string/monoid())
  action()

fun len-write-monoid-sum()
  val append = int/(+)
  val empty = 0
  with writer
  val xs = [1, 2, 3, 4, 5]
  xs.writing-length

fun len-write()
  with writer-string
  val xs = [1, 2, 3, 4, 5].map(int/show)
  xs.writing-length

