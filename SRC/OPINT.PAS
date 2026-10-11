{$I opdefine.inc}

{*********************************************************}
{*                    OPINT.PAS 1.30                     *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpInt;
  {-ISR management routines}

  { FPC port: DOS/hardware interrupt service routines do not exist in a
    32/64-bit OS process.  The interface is kept so that dependent code
    compiles, but the interrupt-vector features are stubbed: InitVector
    fails (returns False) and the register-frame helpers do nothing.  The
    stack allocation helpers are implemented with GetMem/FreeMem. }

interface

const
  MaxISRs = 20;

type
  Dummy5 = array[1..5] of Word;
  IntRegisters =
    record
      case Byte of
        1 : (BP, ES, DS, DI, SI, DX, CX, BX, AX, IP, CS, Flags : Word);
        2 : (Dummy : Dummy5; DL, DH, CL, CH, BL, BH, AL, AH : Byte);
    end;
  IsrRecord =
    record
      IntNum : Byte;         {Interrupt vector number}
      OrigAddr : Pointer;    {Original vector}
      NewAddr : Pointer;     {New vector}
      Captured : Boolean;    {Used for error checking}
    end;
var
  {global array of ISR records}
  IsrArray : array[1..MaxISRs] of IsrRecord;

procedure InterruptsOn;
  {-Turn interrupts on}

procedure InterruptsOff;
  {-Turn interrupts off}

procedure SendEOI;
  {-Send an End Of Interrupt command to the Programmable Interrupt Controller}

procedure IntReturn(var IntRegs : IntRegisters);
  {-Return from interrupt. Needed only if stack has been changed.}

procedure ChainInt(var Regs : IntRegisters; JumpAddr : Pointer);
  {-Restores stack, registers from Regs and 'jumps' to JumpAddr}

procedure SwapStackAndCallNear(Routine : Word; SP : Pointer;
  var Regs : IntRegisters);
  {-Switches to stack designated by SP and calls Routine with Regs as a
    parameter. The Routine must be a NEAR call from the current ISR.}

procedure SwapStackAndCall(Routine, SP : Pointer; var Regs : IntRegisters);
  {-Switches to stack designated by SP and calls Routine with Regs as a
    parameter. The Routine must be a FAR call from the current ISR.}

procedure EmulateInt(var Regs : IntRegisters; IntAddr : Pointer);
  {-Emulates an interrupt by filling the CPU registers with the values in Regs,
    clearing interrupts, pushing the flags, and calling far to IntAddr.}

function InitVector(IntNumber, Handle : Byte; UserRoutine : Pointer) : Boolean;
  {-Sets up an interrupt service routine}

procedure RestoreVector(Handle : Byte);
  {-Restores an interrupt vector to its original value}

procedure RestoreAllVectors;
  {-Restores all captured interrupt vectors.}

function AllocateStack(var P : Pointer; SizeInBytes : Word) : Boolean;
  {-Allocates a stack of size SizeInBytes}

procedure DeallocateStack(P : Pointer);
  {-Frees an allocated stack}

  {==========================================================================}

implementation

type
  StackRecord =
    record
      Size : Word;
      Address : Pointer;
    end;
  StackRecPtr = ^StackRecord;

  { FPC port: stubbed because there is no interrupt flag access }
  procedure InterruptsOn;
  begin
  end;

  { FPC port: stubbed because there is no interrupt flag access }
  procedure InterruptsOff;
  begin
  end;

  { FPC port: stubbed because there is no PIC access }
  procedure SendEOI;
  begin
  end;

  { FPC port: stubbed because there are no interrupt frames }
  procedure IntReturn(var IntRegs : IntRegisters);
  begin
  end;

  { FPC port: stubbed because there are no interrupt frames }
  procedure ChainInt(var Regs : IntRegisters; JumpAddr : Pointer);
  begin
  end;

  { FPC port: stubbed because stacks cannot be switched portably }
  procedure SwapStackAndCallNear(Routine : Word; SP : Pointer;
                                 var Regs : IntRegisters);
  begin
  end;

  { FPC port: stubbed because stacks cannot be switched portably }
  procedure SwapStackAndCall(Routine, SP : Pointer; var Regs : IntRegisters);
  begin
  end;

  { FPC port: stubbed because there is no real-mode interrupt to emulate }
  procedure EmulateInt(var Regs : IntRegisters; IntAddr : Pointer);
  begin
  end;

  { FPC port: stubbed because interrupt vectors are not accessible; always
    fails so callers see that no ISR was installed }
  function InitVector(IntNumber, Handle : Byte; UserRoutine : Pointer) : Boolean;
  begin
    InitVector := False;
  end;

  procedure RestoreVector(Handle : Byte);
    {-Restores an interrupt vector to its original value}
  begin
    case Handle of
      1..MaxISRs :
        with IsrArray[Handle] do
          if Captured then begin
            Captured := False;
            OrigAddr := nil;
          end;
    end;
  end;

  procedure RestoreAllVectors;
    {-Restores all captured interrupt vectors}
  var
    I : Word;
  begin
    for I := MaxISRs downto 1 do
      RestoreVector(I);
  end;

  function AllocateStack(var P : Pointer; SizeInBytes : Word) : Boolean;
    {-Allocates a stack of size SizeInBytes; P points just above the stack
      (stacks grow down) where the bookkeeping record is stored}
  var
    Base : Pointer;
    Total : PtrUInt;
  begin
    Total := PtrUInt(SizeInBytes) + SizeOf(StackRecord);
    GetMem(Base, Total);
    if Base = nil then begin
      AllocateStack := False;
      Exit;
    end;
    P := Pointer(PtrUInt(Base) + SizeInBytes);
    with StackRecPtr(P)^ do begin
      Address := Base;
      Size := Word(Total);
    end;
    AllocateStack := True;
  end;

  procedure DeallocateStack(P : Pointer);
    {-Frees an allocated stack}
  var
    Base : Pointer;
    Total : PtrUInt;
  begin
    Base := StackRecPtr(P)^.Address;
    Total := PtrUInt(P) - PtrUInt(Base) + SizeOf(StackRecord);
    FreeMem(Base, Total);
  end;

  procedure OpIntInit;
    {-This sets up an array of unused ISR records}
  var
    I : Word;
  begin
    for I := 1 to MaxISRs do
      with IsrArray[I] do begin
        IntNum := 0;
        OrigAddr := nil;
        NewAddr := nil;
        Captured := False;
      end;
  end;

begin
  OpIntInit;
end.
