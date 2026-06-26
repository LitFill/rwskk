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
