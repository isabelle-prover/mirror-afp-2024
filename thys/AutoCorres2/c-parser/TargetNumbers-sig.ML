(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

structure BaseCTypes =
struct
  datatype base_inttype = Char | Short | Int | Long | LongLong | Int128 (* | ITY_Word of int *)
end

signature IMPLEMENTATION_NUMBERS =
sig

  type int = IntInf.int
  val UCHAR_MAX : int
  val USHORT_MAX : int
  val UINT_MAX : int
  val ULONG_MAX : int
  val ULLONG_MAX : int
  val UINT128_MAX : int

  val SCHAR_MAX : int
  val CHAR_MAX : int
  val SHORT_MAX : int
  val INT_MAX : int
  val LONG_MAX : int
  val LLONG_MAX : int
  val INT128_MAX : int

  val SCHAR_MIN : int
  val CHAR_MIN : int
  val SHORT_MIN : int
  val INT_MIN : int
  val LONG_MIN : int
  val LLONG_MIN : int
  val INT128_MIN : int

  val char_signedp : bool

  val CHAR_BIT : int
  val boolWidth : int
  val charWidth : int
  val shortWidth : int
  val intWidth : int
  val longWidth : int
  val llongWidth : int
  val int128Width : int
  val ptrWidth : int
  val ptr_t : BaseCTypes.base_inttype

  exception BadChar
  val charliteral_conversion : int -> int

end

signature CHAR_LIT_UTIL =
sig
  exception BadChar
  type int = IntInf.int
  val schar_conv : {umax:int,smin:int,smax:int} -> int -> int
  val uchar_conv : {umax:int} -> int -> int
end

structure CharLitUtil : CHAR_LIT_UTIL =
struct
open IntInf
exception BadChar
fun schar_conv {umax,smin,smax} i = let
  val _ = 0 <= i andalso i <= umax orelse
          raise BadChar
in
  if i > smax then smin + i
  else i
end
fun uchar_conv {umax} i = let
  val _ = 0 <= i andalso i <= umax orelse
          raise BadChar
in
  i
end

end
