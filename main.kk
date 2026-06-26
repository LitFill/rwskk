module main

import rws

struct person
  name : string
  age : int

fun person/show(Person(n, a))
  "Person(name=" ++ n ++ ", age=" ++ a.show ++ ")"

// An action that relies on a string configuration
fun show-port() : <reader<string>> string
  "Current port is: " ++ ask()

// A test action that overrides the environment locally
fun test-local-override() : <reader<string>> string
  val original = show-port()

  // We override the reader effect locally by binding a new handler
  with fun ask() { "8080" }
  val overridden = show-port()

  original ++ " | Overridden: " ++ overridden

type config
  Debug
  Production

// Assumes reader<config>
fun log-message(msg : string) : <reader<config>, console> ()
  match ask()
    Debug -> println("[DEBUG]: " ++ msg)
    Production -> () // Stay silent in production


alias bindings = list<(string, int)>

fun is-count-correct(b : bindings) : bool
  reader(b) { calc-is-count-correct() }

fun calc-is-count-correct() : reader<bindings> bool
  val count = asks(lookup-var("count", _))
  val bs    = ask()
  count == bs.list/length

fun lookup-var(name : string, bs : bindings) : int
  val mv = bs.find fn((k, _v)) k == name
  mv.map(snd).default(0)

val sample-bindings : bindings = [("count", 3), ("1", 1), ("b", 2)]


fun calculate-content-length() : reader<string> int
  val content = ask()
  content.chars/count

fun calculate-modified-content-length() : reader<string> int
  local ("Prefix " ++ _)
    calculate-content-length()

fun print-reader-content() : <reader<string>,console> ()
  val content = ask()
  println("The Reader Content: " ++ content)

fun main ()
  "=== RWS ===".println
  rws()

  "===========".println
  val p = Person(name="LitFill", age=20)
  p.println
  reader(p)
    val p1 : person = ask()
    p1.println
    val n = asks(name)
    n.println
    val p2 = local fn(r : person) { r(name="Alice", age=30) }
      (ask(), asks(age))
    p2.println

  "===========".println
  reader("3000")
    test-local-override().println

  "===========".println
  reader(Debug)
    log-message("Initializing process...")
    log-message("Testing prod...")
    local fn(_) { Production }
      log-message("ERROR: This message shouldn't be shown at all!")
    log-message("Prod tested.")
    log-message("Closing process...")

  "===========".println
  print("Count is correct for bindings " ++ sample-bindings.show ++ ": ")
  sample-bindings.is-count-correct.println

  "===========".println
  val s = "12345"
  val mod-len = s.reader {
    calculate-modified-content-length()
  }
  val len = s.reader {
    calculate-content-length()
  }
  println("Modified 's' length: " ++ mod-len.show)
  println("Original 's' length: " ++ len.show)

  "===========".println
  "Some Content".reader {
    print-reader-content ()
  }

//|====================================================================|//
//|  Elaborate Combined-Effect Demos: Reader, Writer, State            |//
//|                                                                    |//
//|  These demos showcase Koka's algebraic effects working together —  |//
//|  the same thing that requires monad transformers in Haskell is     |//
//|  flat composition of effect handlers here.                         |//
//|====================================================================|//

//|--------------------------------------------------------------------|//
//|  Demo 1: Counter with Audit Log (State + Writer)                   |//
//|                                                                    |//
//|  State tracks a running count. Writer logs every mutation as a     |//
//|  human-readable entry in a string list. The list monoid (++)       |//
//|  accumulates tell() calls automatically.                           |//
//|--------------------------------------------------------------------|//

fun demo-counter()
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

//|--------------------------------------------------------------------|//
//|  Demo 2: Config-Driven Document Processor (Reader + Writer)        |//
//|                                                                    |//
//|  Reader supplies a document config (header, separator, footer).    |//
//|  Writer logs each processing step. The processor formats a list    |//
//|  of items into a document, scoping the reader locally for realism. |//
//|--------------------------------------------------------------------|//

struct doc-config
  header    : string
  separator : string
  footer    : string

fun demo-doc-processor()
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

//|--------------------------------------------------------------------|//
//|  Demo 3: Stack Calculator (Reader + State + Writer — full RWS)     |//
//|                                                                    |//
//|  A tiny stack-based calculator showing all three effects together: |//
//|    Reader: multiplier factor from the environment                  |//
//|    State:  a stack of integers                                     |//
//|    Writer: a trace of every operation                              |//
//|                                                                    |//
//|  In Haskell this would need RWS monad transformer stack. In Koka   |//
//|  it's three nested handlers, no lift/run plumbing.                 |//
//|--------------------------------------------------------------------|//

fun demo-stack-calc()
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
              tell([ (a + b).show
                  ++ " * "
                  ++ factor.show
                  ++ " (env) = "
                  ++ product.show])
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
//|------------------------------------------------------------------|//

fun rws()
  val p = println
  "===== RWS Combined Effect Demos =====".p ; "".p
  demo-counter()                            ; "".p
  demo-doc-processor()                      ; "".p
  demo-stack-calc()                         ; "".p
