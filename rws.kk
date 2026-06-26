module rws

pub import reader
pub import writer
pub import state

//|====================================================================|
//|  Elaborate Combined-Effect Demos: Reader, Writer, State            |
//|                                                                    |
//|  These demos showcase Koka's algebraic effects working together —  |
//|  the same thing that requires monad transformers in Haskell is     |
//|  flat composition of effect handlers here.                         |
//|====================================================================|

//|--------------------------------------------------------------------|
//|  Demo 1: Counter with Audit Log (State + Writer)                   |
//|                                                                    |
//|  State tracks a running count. Writer logs every mutation as a     |
//|  human-readable entry in a string list. The list monoid (++)       |
//|  accumulates tell() calls automatically.                           |
//|--------------------------------------------------------------------|

pub fun demo-counter()
  println("--- Counter with Audit Log (State + Writer) ---")
  val monoid = list/monoid()

  // State wraps: (action-result, final-state)
  // Writer wraps: (action-result, accumulated-log)
  // Composed: ((body-value, log), final-state)
  val ((final-count, log), _) =
    with state(0)
    with writer

    [ "init: count = 0" ].tell
    modify (_ + 5)
    [ "add 5      -> " ++ gets(int/show) ].tell
    modify (_ * 2)
    [ "mul 2      -> " ++ gets(int/show) ].tell
    modify (_ - 3)
    [ "sub 3      -> " ++ gets(int/show) ].tell
    modify (_ / 2)
    [ "div 2      -> " ++ gets(int/show) ].tell
    get()

  println("Final count: " ++ final-count.show)
  println("Operation log:")
  var i := 1
  log.foreach fn(entry)
    println("  " ++ i.show ++ ". " ++ entry)
    i := i + 1

//|--------------------------------------------------------------------|
//|  Demo 2: Config-Driven Document Processor (Reader + Writer)        |
//|                                                                    |
//|  Reader supplies a document config (header, separator, footer).    |
//|  Writer logs each processing step. The processor formats a list    |
//|  of items into a document, scoping the reader locally for realism. |
//|--------------------------------------------------------------------|

pub struct doc-config
  header    : string
  separator : string
  footer    : string

pub fun demo-doc-processor()
  println("--- Document Processor (Reader + Writer) ---")
  val config = Doc-config("=== Document ===", "----------------", "=== End ===")
  val items = ["Introduction", "Methodology", "Results", "Conclusion"]

  val monoid = list/monoid()

  // reader passes the return through unmodified — no result wrapping.
  // writer wraps: (body-value, log)
  val (_res, log) =
    with reader(config)
    with writer

    tell(["config loaded"])

    // Write header from config
    val hdr = asks(header)
    hdr.println
    tell(["header written"])

    // Process each item with config-aware scoping
    items.foreach fn(item)
      val sep = asks(separator)
      sep.println
      item.println
      tell(["processed \"" ++ item ++ "\""])

    // Write footer from config
    val ftr = asks(footer)
    ftr.println
    tell(["footer written"])

    // local reader override: swap the footer for a custom one
    local fn(cfg : doc-config) { cfg(footer="— EOF —") }
      asks(footer).println

  println("Process log:")
  var i := 1
  log.foreach fn(entry)
    println("  " ++ i.show ++ ". " ++ entry)
    i := i + 1

//|--------------------------------------------------------------------|
//|  Demo 3: Stack Calculator (Reader + State + Writer — full RWS)     |
//|                                                                    |
//|  A tiny stack-based calculator showing all three effects together: |
//|    Reader: multiplier factor from the environment                  |
//|    State:  a stack of integers                                     |
//|    Writer: a trace of every operation                              |
//|                                                                    |
//|  In Haskell this would need RWS monad transformer stack. In Koka   |
//|  it's three nested handlers, no lift/run plumbing.                 |
//|--------------------------------------------------------------------|

pub fun demo-stack-calc()
  println("--- Stack Calculator (Reader + State + Writer) ---")
  val monoid = list/monoid()
  val env-factor = 3
  fun glis() gets(list/show(_, int/show))
  val trace =
    with reader(env-factor)
    val ((_result, log), _stack) =
      with state([])
      with writer
      tell(["stack initialized as []"])

      // Push values onto the stack
      modify (_ ++ [10, 20, 30])
      [ "pushed [10, 20, 30] -> " ++ glis() ].tell

      // Pop top two, add them, multiply by environment factor, push back
      match gets(reverse)
        Cons(x : int, Cons(y : int, rest : list<int>)) ->
          val factor = ask()
          val sum    = x + y
          val prod   = sum * factor
          put(rest ++ [prod])
          tell([x.show ++ " + " ++ y.show ++ " = " ++ sum.show])
          tell([sum.show ++ " * " ++ factor.show ++ " (env) = " ++ prod.show])
          [ "stack after op: " ++ glis() ].tell

          // Second operation: push two more, add
          modify (_ ++ [4, 5])
          [ "pushed [4, 5] -> " ++ glis() ].tell

          match gets(reverse)
            Cons(a : int, Cons(b : int, tail : list<int>)) ->
              val product = (a + b) * ask()
              put(tail ++ [product])
              tell([a.show ++ " + " ++ b.show ++ " = " ++ (a + b).show])
              tell([(a + b).show ++ " * " ++ factor.show ++ " (env) = " ++ product.show])
              [ "stack after op: " ++ glis() ].tell

            _ -> tell(["ERROR: not enough operands for second op"])
        _ -> tell(["ERROR: need at least 2 operands on stack"])

      println("Final stack: " ++ glis())
    log

  println("Execution trace:")
  var j := 1
  trace.foreach fn(entry)
    println("  " ++ j.show ++ ". " ++ entry)
    j := j + 1
//|--------------------------------------------------------------------|

pub fun rws()
  val p = println
  "===== RWS Combined Effect Demos =====".p ; "".p
  demo-counter()                            ; "".p
  demo-doc-processor()                      ; "".p
  demo-stack-calc()                         ; "".p
