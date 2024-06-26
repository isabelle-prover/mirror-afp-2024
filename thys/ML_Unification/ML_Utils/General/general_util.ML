(*  Title:      ML_Utils/general_util.ML
    Author:     Kevin Kappelmann

General ML utilities.
*)
signature GENERAL_UTIL =
sig
  val flip : ('a -> 'b -> 'c) -> 'b -> 'a -> 'c

  val find_first_index : ('a -> bool) -> 'a list -> (int * 'a) option
  val find_indices : ('a -> bool) -> 'a list -> int list

  (*returns false if function throws an exception*)
  val try_bool : ('a -> bool) -> 'a -> bool

  (*lists*)
  val fold_rev_index: (int * 'a -> 'b -> 'b) -> 'a list -> 'b -> 'b

  (* sequences *)
  (*raises exception if sequence is empty and returns the sequence otherwise*)
  val seq_try : exn -> 'a Seq.seq -> 'a Seq.seq
  val seq_is_empty : 'a Seq.seq -> (bool * 'a Seq.seq)
  val seq_merge : 'a ord -> ('a Seq.seq * 'a Seq.seq) -> 'a Seq.seq

end

structure General_Util : GENERAL_UTIL =
struct

fun flip f x y = f y x

fun find_first_index p = get_index (Option.filter p)

fun find_indices p =
  let
    fun find_indices _ [] = []
      | find_indices i (x :: xs) = (p x ? cons i) (find_indices (i + 1) xs)
  in find_indices 0 end

fun try_bool f = try f #> (Option.getOpt o rpair false)

(*lists*)
fun fold_rev_index f =
  let fun fold_aux _ [] y = y
        | fold_aux i (x :: xs) y = f (i, x) (fold_aux (i + 1) xs y)
  in fold_aux 0 end

(* sequences *)
fun seq_is_empty sq = case Seq.pull sq of
    NONE => (true, Seq.empty)
  | SOME v => (false, Seq.make (fn () => SOME v))

fun seq_try exn sq = case seq_is_empty sq of
    (true, _) => raise exn
  | (false, sq) => sq

fun seq_merge ord (xq, yq) =
  Seq.make (fn () => (case Seq.pull xq of
      NONE => Seq.pull yq
    | SOME (x, xq') => case Seq.pull yq of
        NONE => Seq.pull xq
      | SOME (y, yq') => case ord (x, y) of
          LESS => SOME (x, seq_merge ord (xq', Seq.cons y yq'))
        | EQUAL => SOME (x, seq_merge ord (xq', Seq.cons y yq'))
        | GREATER => SOME (y, seq_merge ord (Seq.cons x xq', yq')))
  )

end