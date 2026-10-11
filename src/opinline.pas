{$I opdefine.inc}

{*********************************************************}
{*                  OPINLINE.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}
{ Free Pascal port: the original 16-bit x86 INLINE() byte macros have been
  rewritten as ordinary Pascal routines.  Routines that only make sense with
  real-mode segment:offset pointers, interrupts, or far calls are either
  re-expressed for flat pointers or noted below. }

unit OpInline;
  {-Assorted inline macros}

interface

uses
  OpJump;

type
  { JumpRecord is retained for source compatibility.  SetJump has no
    equivalent in portable Free Pascal (it required a raw SP/BP/CS:IP
    snapshot), so non-local exits are implemented with exceptions in unit
    OpJump: see RunJump and LongJump. }
  JumpRecord =
    record
      Result : Word;
    end;

  { Retained for source compatibility with code that decomposes values. }
  OS =
    record
      O, S : Word;
    end;

  LH =
    record
      L, H : Word;
    end;

{$IFNDEF CPUI386}
  { FPC port: the Dos unit only declares Registers on i386; this is the same
    layout so that source using it still compiles on other CPUs.  The DOS
    interrupt calls themselves are stubbed. }
  Registers =
    packed record
      case Integer of
        0 : (AX, F1, BX, F2, CX, F3, DX, F4, BP, F5, SI, F6, DI, F7,
             DS, F8, ES, F9, Flags, FS, GS : Word);
        1 : (AL, AH, F10, F11, BL, BH, F12, F13, CL, CH, F14, F15,
             DL, DH : Byte);
        2 : (EAX, EBX, ECX, EDX, EBP, ESI, EDI : LongInt);
    end;
{$ENDIF}

procedure LongJump(var JumpDest : JumpRecord; Result : Word);
  {-Abandon the innermost active OpJump.RunJump, returning Result from it}

function MakeLongInt(H, L : Word) : LongInt;
  {-Constructs a LongInt from two Words}

function MakeInteger(H, L : Byte): Integer;
  {-Constructs an integer from two bytes}

function MakeWord(H, L : Byte) : Word;
  {-Constructs a word from two bytes}

function Array2Str(var A; Len : Byte) : string;
  {-Convert an array of char to a string}

procedure Reboot;
  {-Reboot the machine. Stubbed: a portable program cannot (and should not)
    reset the computer. Halts the program instead.}

function HiWord(L : LongInt) : Word;
  {-Return high-order word of L}

function LoWord(L : LongInt) : Word;
  {-Return low-order word of L}

function SwapNibble(B : Byte) : Byte;
  {-Swap the high and low nibbles of B: SwapNibble($F0) returns $0F.}

function SwapWord(L : LongInt) : LongInt;
  {-Swap low- and high-order words of L}

function Normalized(P : Pointer) : Pointer;
  {-Return P as a normalized pointer. Pointers are flat in Free Pascal, so
    this is the identity function.}

procedure SetFlag(var Flags : Word; FlagMask : Word);
  {-Set the bit(s) specified by FlagMask in Flags}

procedure ClearFlag(var Flags : Word; FlagMask : Word);
  {-Clear the bit(s) specified by FlagMask in Flags}

function FlagIsSet(Flags, FlagMask : Word) : Boolean;
  {-True if any bit specified by FlagMask is set in Flags}

procedure SetByteFlag(var Flags : Byte; FlagMask : Byte);
  {-Set the bit(s) specified by FlagMask in Flags}

procedure ClearByteFlag(var Flags : Byte; FlagMask : Byte);
  {-Clear the bit(s) specified by FlagMask in Flags}

function ByteFlagIsSet(Flags, FlagMask : Byte) : Boolean;
  {-True if any bit specified by FlagMask is set in Flags}

procedure SetLongFlag(var Flags : LongInt; FlagMask : LongInt);
  {-Set the bit(s) specified by FlagMask in Flags}

procedure ClearLongFlag(var Flags : LongInt; FlagMask : LongInt);
  {-Clear the bit(s) specified by FlagMask in Flags}

function LongFlagIsSet(Flags, FlagMask : LongInt) : Boolean;
  {-True if any bit specified by FlagMask is set in Flags}

procedure ExchangeBytes(var I, J : Byte);
  {-Exchange bytes I and J}

procedure ExchangeWords(var I, J : Word);
  {-Exchange words I and J}

procedure ExchangeLongInts(var I, J : LongInt);
  {-Exchange LongInts I and J}

procedure ExchangeStructs(var I, J; Size : Word);
  {-Exchange structures I and J. Useful in sorts}

function MinWord(A, B : Word) : Word;
  {-Return the smaller of A and B}

function MaxWord(A, B : Word) : Word;
  {-Return the greater of A and B}

function MinLong(A, B : LongInt) : LongInt;
  {-Return the smaller of A and B}

function MaxLong(A, B : LongInt) : LongInt;
  {-Return the greater of A and B}

procedure FillWord(var Dest; Count, Filler : Word);
  {-Fill memory starting at Dest with Count instances of Filler}

procedure FillStruct(var Dest; Count : Word; var Filler; FillerSize : Word);
  {-Fill memory starting at Dest with Count instances of Filler}

function AddWordToPtr(P : Pointer; W : Word) : Pointer;
  {-Add a Word to a pointer}

function LoNibble(N : Byte) : Byte;
  {-Return the low nibble of a byte value}

function HiNibble(N : Byte) : Byte;
  {-Return the high nibble of a byte value}

function MakeByte(H, L : Byte) : Byte;
  {-Construct a byte value from two nibble values}

function PtrToLong(P : Pointer) : LongInt;
  {-Convert pointer to LongInt (low 32 bits of the address)}

function LongToPtr(L : LongInt) : Pointer;
  {-Return LongInt L as a pointer}

function PtrDiff(P1, P2 : Pointer) : LongInt;
  {-Return the number of bytes between P1^ and P2^}

function AddLongToPtr(P : Pointer; L : LongInt) : Pointer;
  {-Add a LongInt to a pointer}

function MaxAvail : LongInt;
  {-FPC port: fixed large value (FPC has no MaxAvail)}
function MemAvail : LongInt;
  {-FPC port: fixed large value (FPC has no MemAvail)}

  {==========================================================================}

implementation

procedure LongJump(var JumpDest : JumpRecord; Result : Word);
begin
  JumpDest.Result := Result;
  LongJumpTo(Result);
end;

function MakeLongInt(H, L : Word) : LongInt;
begin
  MakeLongInt := LongInt((LongWord(H) shl 16) or L);
end;

function MakeInteger(H, L : Byte): Integer;
begin
  MakeInteger := SmallInt((Word(H) shl 8) or L);
end;

function MakeWord(H, L : Byte) : Word;
begin
  MakeWord := (Word(H) shl 8) or L;
end;

function Array2Str(var A; Len : Byte) : string;
var
  S : string;
begin
  S[0] := Chr(Len);
  if Len > 0 then
    Move(A, S[1], Len);
  Array2Str := S;
end;

procedure Reboot;
begin
  Halt(1);
end;

function HiWord(L : LongInt) : Word;
begin
  HiWord := Word((LongWord(L) shr 16) and $FFFF);
end;

function LoWord(L : LongInt) : Word;
begin
  LoWord := Word(LongWord(L) and $FFFF);
end;

function SwapNibble(B : Byte) : Byte;
begin
  SwapNibble := Byte((B shl 4) or (B shr 4));
end;

function SwapWord(L : LongInt) : LongInt;
begin
  SwapWord := LongInt((LongWord(L) shl 16) or (LongWord(L) shr 16));
end;

function Normalized(P : Pointer) : Pointer;
begin
  Normalized := P;
end;

procedure SetFlag(var Flags : Word; FlagMask : Word);
begin
  Flags := Flags or FlagMask;
end;

procedure ClearFlag(var Flags : Word; FlagMask : Word);
begin
  Flags := Flags and not FlagMask;
end;

function FlagIsSet(Flags, FlagMask : Word) : Boolean;
begin
  FlagIsSet := (Flags and FlagMask) <> 0;
end;

procedure SetByteFlag(var Flags : Byte; FlagMask : Byte);
begin
  Flags := Flags or FlagMask;
end;

procedure ClearByteFlag(var Flags : Byte; FlagMask : Byte);
begin
  Flags := Flags and not FlagMask;
end;

function ByteFlagIsSet(Flags, FlagMask : Byte) : Boolean;
begin
  ByteFlagIsSet := (Flags and FlagMask) <> 0;
end;

procedure SetLongFlag(var Flags : LongInt; FlagMask : LongInt);
begin
  Flags := Flags or FlagMask;
end;

procedure ClearLongFlag(var Flags : LongInt; FlagMask : LongInt);
begin
  Flags := Flags and not FlagMask;
end;

function LongFlagIsSet(Flags, FlagMask : LongInt) : Boolean;
begin
  LongFlagIsSet := (Flags and FlagMask) <> 0;
end;

procedure ExchangeBytes(var I, J : Byte);
var
  T : Byte;
begin
  T := I; I := J; J := T;
end;

procedure ExchangeWords(var I, J : Word);
var
  T : Word;
begin
  T := I; I := J; J := T;
end;

procedure ExchangeLongInts(var I, J : LongInt);
var
  T : LongInt;
begin
  T := I; I := J; J := T;
end;

procedure ExchangeStructs(var I, J; Size : Word);
var
  PI, PJ : ^Byte;
  T : Byte;
  K : Word;
begin
  PI := @I;
  PJ := @J;
  for K := 1 to Size do begin
    T := PI^; PI^ := PJ^; PJ^ := T;
    Inc(PI);
    Inc(PJ);
  end;
end;

function MinWord(A, B : Word) : Word;
begin
  if A < B then MinWord := A else MinWord := B;
end;

function MaxWord(A, B : Word) : Word;
begin
  if A > B then MaxWord := A else MaxWord := B;
end;

function MinLong(A, B : LongInt) : LongInt;
begin
  if A < B then MinLong := A else MinLong := B;
end;

function MaxLong(A, B : LongInt) : LongInt;
begin
  if A > B then MaxLong := A else MaxLong := B;
end;

procedure FillWord(var Dest; Count, Filler : Word);
var
  P : ^Word;
  K : Word;
begin
  P := @Dest;
  for K := 1 to Count do begin
    P^ := Filler;
    Inc(P);
  end;
end;

procedure FillStruct(var Dest; Count : Word; var Filler; FillerSize : Word);
var
  P : ^Byte;
  K : Word;
begin
  P := @Dest;
  for K := 1 to Count do begin
    Move(Filler, P^, FillerSize);
    Inc(P, FillerSize);
  end;
end;

function AddWordToPtr(P : Pointer; W : Word) : Pointer;
begin
  AddWordToPtr := Pointer(PtrUInt(P) + W);
end;

function LoNibble(N : Byte) : Byte;
begin
  LoNibble := N and $0F;
end;

function HiNibble(N : Byte) : Byte;
begin
  HiNibble := N shr 4;
end;

function MakeByte(H, L : Byte) : Byte;
begin
  MakeByte := Byte((H shl 4) or (L and $0F));
end;

function PtrToLong(P : Pointer) : LongInt;
begin
  PtrToLong := LongInt(PtrUInt(P) and $FFFFFFFF);
end;

function LongToPtr(L : LongInt) : Pointer;
begin
  LongToPtr := Pointer(PtrUInt(LongWord(L)));
end;

function PtrDiff(P1, P2 : Pointer) : LongInt;
begin
  if PtrUInt(P1) >= PtrUInt(P2) then
    PtrDiff := LongInt(PtrUInt(P1) - PtrUInt(P2))
  else
    PtrDiff := LongInt(PtrUInt(P2) - PtrUInt(P1));
end;

function AddLongToPtr(P : Pointer; L : LongInt) : Pointer;
begin
  AddLongToPtr := Pointer(PtrInt(P) + L);
end;

{FPC port: FPC has no MaxAvail/MemAvail; report a fixed generous amount}
function MaxAvail : LongInt;
begin
  MaxAvail := 128*1024*1024;
end;

function MemAvail : LongInt;
begin
  MemAvail := 128*1024*1024;
end;

{$IFDEF InitAllUnits}
begin
{$ENDIF}
end.
