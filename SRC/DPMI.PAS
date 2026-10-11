{$I opdefine.inc}

{*********************************************************}
{*                     DPMI.PAS 1.00                     *}
{*        Copyright (c) TurboPower Software 1992.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit Dpmi;       {primitive routines for DPMI management}

{ Free Pascal port: STUBBED.
  DPMI (DOS Protected Mode Interface) is a DOS-extender service for selector
  and real-mode-interrupt management.  It has no meaning on Windows or Linux,
  where programs run in a flat, protected address space managed by the OS.
  This unit therefore only keeps the constants and record types that other
  Object Professional units reference so that they continue to compile.
  All of the descriptor/real-mode-call routines have been removed. }

interface

{-The following consts are used throughout Object Professional.  Your code
  is free to reference them, but they must *not* be changed.}
const
  DpmiInUse : Boolean = False;        {always False: no DPMI on this platform}
  ColorSele : Word = $B800;           {unused: no video memory access}
  MonoSele  : Word = $B000;           {unused: no video memory access}
  BiosDataSele : Word = $0040;        {unused: no BIOS data area}
  BiosSele : Word = $F000;            {unused: no BIOS memory}
  SelectorInc : Word = 0;             {unused: no selectors}

type
  DoubleWord = record
                 LoWord  : Word;
                 HiWord  : Word;
               end;

  {Retained only so that code which declares register records still compiles.
   Nothing can be done with it.}
  DPMIRegisters =
    record
      DI : LongInt;
      SI : LongInt;
      BP : LongInt;
      Reserved : LongInt;
      BX : LongInt;
      DX : LongInt;
      CX : LongInt;
      AX : LongInt;
      Flags : Word;
      ES : Word;
      DS : Word;
      FS : Word;
      GS : Word;
      IP : Word;
      CS : Word;
      SP : Word;
      SS : Word;
    end;

function CallFarRealModeProc(StackWords : Word; StackData : Pointer;
                             var Regs : DPMIRegisters) : Word;
  {-Stub: always returns 1 (failure); real-mode calls do not exist here}

function SimulateRealModeInt(IntNo : Byte;
                             var Regs : DPMIRegisters) : Word;
  {-Stub: always returns 1 (failure); real-mode interrupts do not exist here}

implementation

function CallFarRealModeProc(StackWords : Word; StackData : Pointer;
                             var Regs : DPMIRegisters) : Word;
begin
  CallFarRealModeProc := 1;
end;

function SimulateRealModeInt(IntNo : Byte;
                             var Regs : DPMIRegisters) : Word;
begin
  SimulateRealModeInt := 1;
end;

end.
