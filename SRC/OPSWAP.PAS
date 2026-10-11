{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$IFDEF Dpmi}                                                         {!!.20}
  !! This unit cannot be used in protected mode !!                    {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F-,O-,A-}

{$I opdefine.inc}

{*********************************************************}
{*                    OPSWAP.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1989, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpSwap;
  { FPC port: stubbed because TSR program swapping has no equivalent on
    Windows/Linux. }

interface

var
  SaveInt05 : Pointer;

{.Z+}
function SwapOut : Boolean;

procedure CSRelData;
  {-not a procedure, just a label used by OpSwap1}

function Intercom(Func : Byte) : Pointer;
  {-Routine used to get information from OpSwap1 about code segment}
{.Z-}

procedure SetPopTicker(TimeOut : Word);
  {-Sets the pop ticker for the CmdEntry procedure, clears interrupts,
    then returns.}

{$IFDEF SupportXms}        {!!.02}
procedure UsingXms;
{$ELSE}
procedure NotUsingXms;
{$ENDIF}

  {==========================================================================}

implementation

uses
  OpSwap1;

{ FPC port: stubbed because the resident swap kernel (OPSWAP.ASM/OPSWAPI.ASM:
  ISR handlers, program swap to EMS/XMS/disk, code-segment data area) cannot
  exist on Windows/Linux.  SwapOut reports failure, Intercom returns Nil and
  CSRelData is an empty placeholder.  SetPopTicker works on the heap-based
  CSSwapData of OpSwap1 but nothing ever fires a popup. }

  function SwapOut : Boolean;
  begin
    { FPC port: stubbed because there is no program image swapping }
    SwapOut := False;
  end;

  procedure CSRelData;
  begin
    { FPC port: was a label in the code segment; kept for interface only }
  end;

  function Intercom(Func : Byte) : Pointer;
  begin
    { FPC port: stubbed because there is no resident kernel to query }
    Intercom := nil;
  end;

  procedure SetPopTicker(TimeOut : Word);
  begin
    with CSSwapData^ do begin
      if PopupsEnabled then begin
        if not PopupInUse[CmdEntryHandle] then begin
          InterruptsOff;
          PopupInUse[CmdEntryHandle] := True;
          PopupToCall := CmdEntryHandle;
          PopTicker := TimeOut;
        end;
      end;
    end;
  end;

{$IFDEF SupportXms}
  procedure UsingXms;
  begin
    { FPC port: stubbed because XMS swapping does not exist }
  end;
{$ELSE}
  procedure NotUsingXms;
  begin
    { FPC port: stubbed because XMS swapping does not exist }
  end;
{$ENDIF}

begin
  IntercomPtr := Intercom;
  InitCSSwapData;
end.
