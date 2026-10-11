
{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I opdefine.inc}

{*********************************************************}
{*                  OPASCIIZ.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpAsciiz;
  {-Routines to support ASCIIZ strings}

interface

uses
  OpString;

const
  MaxAsciiz = 1024;          {Maximum length of Asciiz - increase up to 65520}
  NotFound = $FFFF;          {Returned by the Pos functions if substring not found}

type
  Asciiz = array[0..MaxAsciiz] of Char;
  AsciizPtr = ^Asciiz;

function Asc2Str(var A : Asciiz) : string;
  {-Convert Asciiz to Turbo string, truncating if longer than 255 chars}

procedure Str2Asc(S : string; var A : Asciiz);
  {-Convert a Turbo string into an Asciiz}

function LenAsc(const A : Asciiz) : Word;
  {-Return the length of an Asciiz string}
  {FPC port: former inline macro; A is now passed by reference (const)}

procedure CopyAsc(var A : Asciiz; Start, Len : Word; var O : Asciiz);
  {-Return a substring of a. Note start=0 for first char in a}

procedure DeleteAsc(var A : Asciiz; Start, Len : Word);
  {-Delete len characters of a, starting at position start}

procedure ConcatAsc(var A, B, C : Asciiz);
  {-Concatenate two Asciiz strings, returning a third}

procedure ConcatStr(var A : Asciiz; S : string; var C : Asciiz);
  {-Concatenate a string to an asciiz, returning a new asciiz}

procedure InsertAsc(var Obj, A : Asciiz; Start : Word);
  {-Insert asciiz obj at position start of a}

procedure InsertStr(Obj : string; var A : Asciiz; Start : Word);
  {-Insert string obj at position start of a}

function PosStr(Obj : string; var A : Asciiz) : Word;
  {-Return the position of the string obj in a, returning NotFound if not found}

function PosAsc(var Obja, A : Asciiz) : Word;
  {-Return the position of obja in a, returning NotFound if not found}

function AscToHeap(var A : Asciiz) : AsciizPtr;
  {-Put Asciiz on heap, returning a pointer, nil if insufficient memory}

procedure AscFromHeap(P : AsciizPtr; var A : Asciiz);
  {-Return an Asciiz from the heap, empty if pointer is nil}

procedure DisposeAsc(P : AsciizPtr);
  {-Dispose of heap space pointed to by P}

function ReadLnAsc(var F : Text; var A : Asciiz) : Boolean;
  {-Read an Asciiz from text file, returning true if successful}

function WriteAsc(var F : Text; var A : Asciiz) : Boolean;
  {-Write an Asciiz to text file, returning true if successful}

procedure AscUpcase(var A, B : Asciiz);
  {-Uppercase the Asciiz in a, returning b}

procedure AscLocase(var A, B : Asciiz);
  {-Lowercase the Asciiz in a, returning b}

procedure AscCharStr(Ch : Char; Len : Word; var A : Asciiz);
  {-Return an Asciiz of length len filled with ch}

procedure AscPadCh(var A : Asciiz; Ch : Char; Len : Word; var B : Asciiz);
  {-Right-pad the Asciiz in a to length len with ch, returning b}

procedure AscPad(var A : Asciiz; Len : Word; var B : Asciiz);
  {-Right-pad the Asciiz in a to length len with blanks, returning b}

procedure AscLeftPadCh(var A : Asciiz; Ch : Char; Len : Word; var B : Asciiz);
  {-Left-pad the Asciiz in a to length len with ch, returning b}

procedure AscLeftPad(var A : Asciiz; Len : Word; var B : Asciiz);
  {-Left-pad the Asciiz in a to length len with blanks, returning b}

procedure AscTrimLead(var A, B : Asciiz);
  {-Return an Asciiz with leading white space removed}

procedure AscTrimTrail(var A, B : Asciiz);
  {-Return an Asciiz with trailing white space removed}

procedure AscTrim(var A, B : Asciiz);
  {-Return an Asciiz with leading and trailing white space removed}

procedure AscCenterCh(var A : Asciiz; Ch : Char; Width : Word; var B : Asciiz);
  {-Return an Asciiz centered in an Asciiz of Ch with specified width}

procedure AscCenter(var A : Asciiz; Width : Word; var B : Asciiz);
  {-Return an Asciiz centered in an Asciiz of blanks with specified width}

type
  AscCompareType = (AscLess, AscEqual, AscGreater);

function CompAsc(var a1, a2 : Asciiz) : AscCompareType;
  {-Return less, equal, greater if a1<a2, a1=a2, or a1>a2}

function CompUCAsc(var a1, a2 : Asciiz) : AscCompareType;
  {-Compare two Asciizs in a case insensitive manner}

  {==========================================================================}

implementation

const
  Null = #0;

  function LenAsc(const A : Asciiz) : Word;
  var
    N : Word;
  begin
    N := 0;
    while (N < MaxAsciiz) and (A[N] <> Null) do
      Inc(N);
    LenAsc := N;
  end;

  function Asc2Str(var A : Asciiz) : string;
    {-Convert ASCIIZ to Turbo string, truncating if longer than 255 chars}
  var
    S : string;
    Len : Word;
  begin
    Len := LenAsc(A);
    if Len > 255 then
      Len := 255;
    S[0] := Char(Len);
    MoveFast(A, S[1], Len);  {!!.01}
    Asc2Str := S;
  end;

  procedure Str2Asc(S : string; var A : Asciiz);
    {-Convert a Turbo string into an ASCIIZ}
  begin
    MoveFast(S[1], A, Length(S));  {!!.01}
    A[Length(S)] := Null;
  end;

  procedure CopyAsc(var A : Asciiz; Start, Len : Word; var O : Asciiz);
    {-Return a substring of a. Note start=0 for first char in a}
  var
    alen : Word;
  begin
    alen := LenAsc(A);
    if Start > alen then
      {Return null string}
      O[0] := Null
    else begin
      {Don't copy more than exists}
      if Longint(Start)+Len > alen then {!!.11}
        Len := alen-Start;
      MoveFast(A[Start], O, Len);  {!!.01}
      O[Len] := Null;
    end;
  end;

  procedure DeleteAsc(var A : Asciiz; Start, Len : Word);
    {-Delete len characters of a, starting at position start}
  var
    alen : Word;
    mid : Word;
  begin
    alen := LenAsc(A);
    if Start < alen then begin
      {Don't do anything if start position exceeds length of string}
      mid := Start+Len;
      if mid < alen then begin
        {Move right remainder of string left}
        MoveFast(A[mid], A[Start], alen-mid);  {!!.01}
        A[alen-Len] := Null;
      end else
        {Entire end of string deleted}
        A[Start] := Null;
    end;
  end;

  procedure ConcatAsc(var A, B, C : Asciiz);
    {-Concatenate two Asciiz strings, returning a third}
  var
    alen : Word;
    blen : Word;
  begin
    alen := LenAsc(A);
    blen := LenAsc(B);

    {Put a into the result}
    MoveFast(A, C, alen);  {!!.01}

    {Store as much of b as fits into result}
    if alen+blen > MaxAsciiz then
      blen := MaxAsciiz-alen;
    MoveFast(B, C[alen], blen);  {!!.01}

    {Terminate the result}
    C[alen+blen] := Null;
  end;

  procedure ConcatStr(var A : Asciiz; S : string; var C : Asciiz);
    {-Concatenate a string to an asciiz, returning a new asciiz}
  var
    alen : Word;
    slen : Word;
  begin
    alen := LenAsc(A);
    slen := Length(S);

    {Put a into the result}
    MoveFast(A, C, alen);  {!!.01}

    {Store as much of s as fits into result}
    if alen+slen > MaxAsciiz then
      slen := MaxAsciiz-alen;
    MoveFast(S[1], C[alen], slen);  {!!.01}

    {Terminate the result}
    C[alen+slen] := Null;
  end;

  procedure InsertAsc(var Obj, A : Asciiz; Start : Word);
    {-Insert asciiz obj at position start of a}
  var
    alen : Word;
    olen : Word;
    mid : Word;
  begin
    alen := LenAsc(A);
    olen := LenAsc(Obj);

    if Start > alen then
      {Concatenate if start exceeds alen}
      Start := alen

    else begin
      {Move right side characters right to make space for insert}
      mid := Start+olen;
      if mid < MaxAsciiz then
        {Room for at least some of the right side characters}
        if alen+olen < MaxAsciiz then
          {Room for all of the right side}
          MoveFast(A[Start], A[mid], alen-Start)  {!!.01}
        else
          {Room for part of the right side}
          MoveFast(A[Start], A[mid], MaxAsciiz-mid);  {!!.01}
    end;

    {Insert the obj string}
    if Start+olen >= MaxAsciiz then
      olen := MaxAsciiz-Start;
    MoveFast(Obj, A[Start], olen);  {!!.01}

    {Terminate the string}
    if alen+olen < MaxAsciiz then
      A[alen+olen] := Null
    else
      A[MaxAsciiz] := Null;
  end;

  procedure InsertStr(Obj : string; var A : Asciiz; Start : Word);
    {-Insert string obj at position start of a}
  var
    alen : Word;
    olen : Word;
    mid : Word;
  begin
    alen := LenAsc(A);
    olen := Length(Obj);

    if Start > alen then
      {Concatenate if start exceeds alen}
      Start := alen

    else begin
      {Move right side characters right to make space for insert}
      mid := Start+olen;
      if mid < MaxAsciiz then
        {Room for at least some of the right side characters}
        if alen+olen < MaxAsciiz then
          {Room for all of the right side}
          MoveFast(A[Start], A[mid], alen-Start)  {!!.01}
        else
          {Room for part of the right side}
          MoveFast(A[Start], A[mid], MaxAsciiz-mid);  {!!.01}
    end;

    {Insert the obj string}
    if Start+olen >= MaxAsciiz then
      olen := MaxAsciiz-Start;
    MoveFast(Obj[1], A[Start], olen);  {!!.01}

    {Terminate the string}
    if alen+olen < MaxAsciiz then
      A[alen+olen] := Null
    else
      A[MaxAsciiz] := Null;
  end;

  {FPC port: Search is OpString.Search; the assembler routines below were
   ported to Pascal}
  procedure AscUpcase(var A, B : Asciiz);
    {-Uppercase the Asciiz in a, returning b}
  var
    I : Word;
  begin
    I := 0;
    while A[I] <> Null do begin
      B[I] := Upcase(A[I]);
      Inc(I);
    end;
    B[I] := Null;
  end;

  procedure AscLocase(var A, B : Asciiz);
    {-Lowercase the Asciiz in a, returning b}
  var
    I : Word;
  begin
    I := 0;
    while A[I] <> Null do begin
      B[I] := LoCase(A[I]);
      Inc(I);
    end;
    B[I] := Null;
  end;

  function CompAsc(var a1, a2 : Asciiz) : AscCompareType;
    {-Return less, equal, greater if a1<a2, a1=a2, or a1>a2}
  var
    I : LongInt;
    L1, L2, N : Word;
  begin
    L1 := LenAsc(a1);
    L2 := LenAsc(a2);
    N := L1;
    if L2 < N then
      N := L2;
    for I := 0 to LongInt(N)-1 do
      if a1[I] <> a2[I] then begin
        if a1[I] < a2[I] then
          CompAsc := AscLess
        else
          CompAsc := AscGreater;
        Exit;
      end;
    if L1 = L2 then
      CompAsc := AscEqual
    else if L1 < L2 then
      CompAsc := AscLess
    else
      CompAsc := AscGreater;
  end;

  function CompUCAsc(var a1, a2 : Asciiz) : AscCompareType;
    {-Compare two Asciizs in a case insensitive manner}
  var
    I : LongInt;
    L1, L2, N : Word;
    C1, C2 : Char;
  begin
    L1 := LenAsc(a1);
    L2 := LenAsc(a2);
    N := L1;
    if L2 < N then
      N := L2;
    for I := 0 to LongInt(N)-1 do begin
      C1 := Upcase(a1[I]);
      C2 := Upcase(a2[I]);
      if C1 <> C2 then begin
        if C1 < C2 then
          CompUCAsc := AscLess
        else
          CompUCAsc := AscGreater;
        Exit;
      end;
    end;
    if L1 = L2 then
      CompUCAsc := AscEqual
    else if L1 < L2 then
      CompUCAsc := AscLess
    else
      CompUCAsc := AscGreater;
  end;

  function PosStr(Obj : string; var A : Asciiz) : Word;
    {-Return the position of the string obj in a, returning NotFound if not found}
  begin
    PosStr := Search(A, LenAsc(A), Obj[1], Length(Obj));
  end;

  function PosAsc(var Obja, A : Asciiz) : Word;
    {-Return the position of obja in a, returning NotFound if not found}
  begin
    PosAsc := Search(A, LenAsc(A), Obja, LenAsc(Obja));
  end;

  function AscToHeap(var A : Asciiz) : AsciizPtr;
    {-Put Asciiz on heap, returning a pointer, nil if insufficient memory}
  var
    alen : Word;
    P : AsciizPtr;
  begin
    alen := Succ(LenAsc(A));
    GetMem(P, alen);
    MoveFast(A, P^, alen);  {!!.01}
    AscToHeap := P;
  end;

  procedure AscFromHeap(P : AsciizPtr; var A : Asciiz);
    {-Return an Asciiz from the heap, empty if pointer is nil}
  begin
    if P = nil then
      A[0] := Null
    else
      MoveFast(P^, A, Succ(LenAsc(P^)));  {!!.01}
  end;

  procedure DisposeAsc(P : AsciizPtr);
    {-Dispose of heap space pointed to by P}
  begin
    if P <> nil then
      FreeMem(P, Succ(LenAsc(P^)));
  end;

  procedure AscCharStr(Ch : Char; Len : Word; var A : Asciiz);
    {-Return an Asciiz of length len filled with ch}
  begin
    if Len = 0 then
      A[0] := Null
    else begin
      if Len > MaxAsciiz then
        Len := MaxAsciiz;
      FillChar(A, Len, Ch);
      A[Len] := Null;
    end;
  end;

  procedure AscPadCh(var A : Asciiz; Ch : Char; Len : Word; var B : Asciiz);
    {-Right-pad the Asciiz in a to length len with ch, returning b}
  var
    alen : Word;
  begin
    alen := LenAsc(A);
    if alen >= Len then
      {Return the input string}
      MoveFast(A, B, Succ(alen))  {!!.01}
    else begin
      if Len > MaxAsciiz then
        Len := MaxAsciiz;
      MoveFast(A, B, alen);  {!!.01}
      FillChar(B[alen], Len-alen, Ch);
      B[Len] := Null;
    end;
  end;

  procedure AscPad(var A : Asciiz; Len : Word; var B : Asciiz);
    {-Right-pad the Asciiz in a to length len with blanks, returning b}
  begin
    AscPadCh(A, ' ', Len, B);
  end;

  procedure AscLeftPadCh(var A : Asciiz; Ch : Char; Len : Word; var B : Asciiz);
    {-Left-pad the Asciiz in a to length len with ch, returning b}
  var
    alen : Word;
  begin
    alen := LenAsc(A);
    if alen >= Len then
      {Return the input string}
      MoveFast(A, B, Succ(alen))  {!!.01}
    else begin
      FillChar(B, Len-alen, Ch);
      MoveFast(A, B[Len-alen], alen);  {!!.01}
      B[Len] := Null;
    end;
  end;

  procedure AscLeftPad(var A : Asciiz; Len : Word; var B : Asciiz);
    {-Left-pad the Asciiz in a to length len with blanks, returning b}
  begin
    AscLeftPadCh(A, ' ', Len, B);
  end;

  procedure AscTrimLead(var A, B : Asciiz);
    {-Return an Asciiz with leading white space removed}
  var
    alen : Word;
    apos : Word;
  begin
    alen := LenAsc(A);
    apos := 0;
    while (apos < alen) and (A[apos] <= ' ') do
      Inc(apos);
    MoveFast(A[apos], B, Succ(alen-apos));  {!!.01}
  end;

  procedure AscTrimTrail(var A, B : Asciiz);
    {-Return an Asciiz with trailing white space removed}
  var
    alen : Word;
  begin
    alen := LenAsc(A);
    while (alen > 0) and (A[Pred(alen)] <= ' ') do
      Dec(alen);
    MoveFast(A, B, alen);  {!!.01}
    B[alen] := Null;
  end;

  procedure AscTrim(var A, B : Asciiz);
    {-Return an Asciiz with leading and trailing white space removed}
  var
    blen : Word;
  begin
    AscTrimLead(A, B);
    blen := LenAsc(B);
    while (blen > 0) and (B[Pred(blen)] <= ' ') do
      Dec(blen);
    B[blen] := Null;
  end;

  procedure AscCenterCh(var A : Asciiz; Ch : Char; Width : Word; var B : Asciiz);
    {-Return an Asciiz centered in an Asciiz of Ch with specified width}
  var
    alen : Word;
  begin
    alen := LenAsc(A);
    if alen >= Width then
      {Return input}
      MoveFast(A, B, Succ(alen))  {!!.01}
    else begin
      FillChar(B, Width, Ch);
      MoveFast(A, B[(Width-alen) shr 1], alen);  {!!.01}
      B[Width] := Null;
    end;
  end;

  procedure AscCenter(var A : Asciiz; Width : Word; var B : Asciiz);
    {-Return an Asciiz centered in an Asciiz of blanks with specified width}
  begin
    AscCenterCh(A, ' ', Width, B);
  end;

  function ReadLnAsc(var F : Text; var A : Asciiz) : Boolean;
    {-Read an Asciiz from text file, returning true if successful}
    {FPC port: the Turbo Pascal text-buffer (FIB) scanning was replaced by
     Read/Eoln/ReadLn, which accept CR, LF and CR/LF line ends.  Characters
     beyond MaxAsciiz are discarded, as before.}
  var
    alen : Word;
    Ch : Char;
    Stripped : Boolean;
  begin
    alen := 0;
    ReadLnAsc := False;

    {Make sure file open for input}
    if TextRec(F).Mode <> fmInput then
      Exit;

    {Nothing left to read}
    if Eof(F) then
      Exit;

    while not Eoln(F) do begin
      Read(F, Ch);
      if IoResult <> 0 then
        Exit;
      if alen < MaxAsciiz then begin
        A[alen] := Ch;
        Inc(alen);
      end;
    end;
    ReadLn(F);
    if IoResult <> 0 then
      Exit;

    {Remove trailing ^Z at end of file}
    Stripped := False;
    if Eof(F) then
      while (alen > 0) and (A[Pred(alen)] = ^Z) do begin
        Dec(alen);
        Stripped := True;
      end;
    if Stripped and (alen = 0) then
      Exit;

    {Return success and terminate the Asciiz}
    ReadLnAsc := True;
    A[alen] := Null;
  end;

  function WriteAsc(var F : Text; var A : Asciiz) : Boolean;
    {-Write an Asciiz to text file, returning true if successful}
  var
    S : string;
    alen : Word;
    apos : Word;
    slen : Word;
  begin
    alen := LenAsc(A);
    apos := 0;
    WriteAsc := False;

    {Write the ASCIIZ as a series of strings}
    while apos < alen do begin
      slen := alen-apos;
      if slen > 255 then
        slen := 255;
      S[0] := Chr(slen);
      MoveFast(A[apos], S[1], slen);  {!!.01}
      Write(F, S);
      if IoResult <> 0 then
        Exit;
      Inc(apos, slen);
    end;

    WriteAsc := True;
  end;

{$IFDEF InitAllUnits}
begin
{$ENDIF}
end.
