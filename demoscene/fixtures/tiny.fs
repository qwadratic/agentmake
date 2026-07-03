\ tiny fixture: attn golden-test corpus (do not edit — attn-selfcheck.py pins it)
variable depth

: spaces ( n -- )
  begin dup 0 > if 32 emit 1 - 0 else -1 then until drop ;

: ind depth @ spaces ;

: greet ." hi" cr ;

ind
greet frobnicate 42 .
