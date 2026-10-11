{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$IFDEF Dpmi}                                                         {!!.20}
  !! This unit cannot be used in protected mode !!                    {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F+,O+,A-}

{$I opdefine.inc}

{*********************************************************}
{*                  OPEXTMEM.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpExtMem;
  {-Extended memory management routines}
  { FPC port: stubbed because INT 15h extended memory / VDISK / RAMDRIVE access
    does not exist on Windows/Linux; behaves like the original on a PC/XT
    (no extended memory available). }

  {
  These routines allow you to access extended memory under DOS 3.x without
  colliding with VDISK or Microsoft's RAMDRIVE.SYS. To access the memory, you
  should:

  1. Find out how much is available with ExtMemAvail.
  2. Use GetExtMem to allocate the total amount that you will use.
  3. Use MoveExtMem to access the memory.
  4. Keep in mind that the memory you allocate may not be accessable to other
     programs even after you deallocate it. For this reason, you should not
     allocate more memory than you need for any purpose.
  5. Allocated memory must be deallocated in reverse order.
  }

interface

type
  {a HugePtr holds a 24 bit physical address - can be cast to a LongInt and
   vice versa for indexing purposes}
  HugePtr = Pointer;

function PtrToHuge(P : Pointer) : HugePtr;
  {-Converts a pointer to a huge pointer. The pointer must be in the range
    $0:$0 to $FFFF:$000F.}

procedure MoveExtMem(Src, Dest : HugePtr; WCount : Word);
  {-Move WCount words of extended memory from Src to Dest.}

function ExtMemTotal : LongInt;
  {-Returns total number of bytes of extended memory in the system.}

function ExtMemAvail : Word;
  {-Returns the number of KB of extended memory that is actually free.}

function GetExtMem(N : Word) : HugePtr;
  {-Allocate N Kb of extended memory.  Returns Nil if insufficient memory.}

function FreeExtMem(P : HugePtr) : Boolean;
  {-Deallocates extended memory which has been allocated with GetExtMem. It
    works only if the block to deallocate is the last block allocated by your
    program or any other. Returns false if deallocation failed.}

procedure MarkExtMem(var P : HugePtr);
  {-Store the location of the next extended memory block in P}

procedure ReleaseExtMem(P : HugePtr);
  {-Release all extended memory above P. P *must* have been set by
    MarkExtMem. It cannot be a huge pointer returned by GetExtMem.}

  {==========================================================================}

implementation

{ FPC port: stubbed because INT 15h extended memory access (AH=87h block move,
  AH=88h size, VDISK/RAMDRIVE control-block scanning, GDT, BIOS machine-ID
  byte at FFFF:000E) is impossible on Windows/Linux.  Behaviour equals the
  original with AllowAllocation = False (PC/XT/DOS 2.x case): ExtMemTotal and
  ExtMemAvail return 0, GetExtMem returns Nil, FreeExtMem returns False,
  MoveExtMem/ReleaseExtMem do nothing, MarkExtMem stores Nil. }

  function PtrToHuge(P : Pointer) : HugePtr;
    {-Converts a pointer to a huge pointer.}
  begin
    { FPC port: pointers are flat; no segment:offset decomposition }
    PtrToHuge := P;
  end;

  procedure MoveExtMem(Src, Dest : HugePtr; WCount : Word);
    {-Move WCount words of extended memory from Src to Dest.}
  begin
    { FPC port: stubbed because there is no BIOS extended memory }
  end;

  function ExtMemTotal : LongInt;
    {-Returns total number of bytes of extended memory in the system.}
  begin
    { FPC port: stubbed because there is no BIOS extended memory }
    ExtMemTotal := 0;
  end;

  function ExtMemAvail : Word;
    {-Returns the number of KB of extended memory that is actually free.}
  begin
    { FPC port: stubbed because there is no BIOS extended memory }
    ExtMemAvail := 0;
  end;

  function GetExtMem(N : Word) : HugePtr;
    {-Allocate N KB of extended memory.  Returns Nil if insufficient memory.}
  begin
    { FPC port: stubbed because there is no BIOS extended memory }
    GetExtMem := nil;
  end;

  function FreeExtMem(P : HugePtr) : Boolean;
    {-Deallocates extended memory which has been allocated with GetExtMem.}
  begin
    { FPC port: stubbed because there is no BIOS extended memory }
    FreeExtMem := False;
  end;

  procedure MarkExtMem(var P : HugePtr);
    {-Store the location of the next extended memory block in P}
  begin
    { FPC port: stubbed because there is no BIOS extended memory }
    P := nil;
  end;

  procedure ReleaseExtMem(P : HugePtr);
    {-Release all extended memory above P.}
  begin
    { FPC port: stubbed because there is no BIOS extended memory }
  end;

end.
