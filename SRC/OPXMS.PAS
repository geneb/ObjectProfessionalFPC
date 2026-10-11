
{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$IFDEF Dpmi}                                                         {!!.20}
  !! This unit cannot be used in protected mode !!                    {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F-,O-,A-}

{$I opdefine.inc}

{*********************************************************}
{*                   OPXMS.PAS 1.30                      *}
{*       Copyright (c) TurboPower Software 1989, 1992.   *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpXms;
  {-XMS memory management routines}
  { FPC port: stubbed because XMS (INT 2Fh driver, far-call control proc, HMA,
    A20) has no equivalent on Windows/Linux; reports 'XMS not installed'. }

interface

type
  {pointers in XMS are segm:ofs for < 1 meg, and linear for > 1 meg}
  ExtMemPtr      =
    record
      case Boolean of
        False : (RealPtr : Pointer);
        True  : (ProtectedPtr : LongInt);
    end;

  {the record structure used internally by MoveExtMemBlock}
  ExtMemMoveStruct =
    record
      Len        : LongInt;
      SrcHand    : Word;
      SrcOffs    : ExtMemPtr;
      DestHand   : Word;
      DestOffs   : ExtMemPtr;
    end;

var
  XmsControl       : Pointer;          {ptr to XMS control procedure}

const
  FuncNotImplemented   = $80;          {function is not implemented}
  VDiskDeviceDetected  = $81;          {a VDISK compatible device found}
  A20Error             = $82;          {an A20 error occurred}
  GeneralDriverError   = $8E;          {general driver error}
  UnrecoverableError   = $8F;          {unrecoverable driver error}
  HmaDoesNotExist      = $90;          {high memory area does not exist}
  HmaAlreadyInUse      = $91;          {high memory area already in use}
  HmaSizeTooSmall      = $92;          {size requested less than /HMAMIN}
  HmaNotAllocated      = $93;          {high memory area not allocated}
  A20StillEnabled      = $94;          {A20 line is still enabled}
  AllExtMemAllocated   = $A0;          {all extended memory is allocated}
  OutOfExtMemHandles   = $A1;          {extended memory handles exhausted}
  InvalidHandle        = $A2;          {invalid handle}
  InvalidSourceHandle  = $A3;          {invalid source handle}
  InvalidSourceOffset  = $A4;          {invalid source offset}
  InvalidDestHandle    = $A5;          {invalid destination handle}
  InvalidDestOffset    = $A6;          {invalid destination offset}
  InvalidLength        = $A7;          {invalid length}
  OverlapInMoveReq     = $A8;          {overlap in move request}
  ParityErrorDetected  = $A9;          {parity error detected}
  BlockIsNotLocked     = $AA;          {block is not locked}
  BlockIsLocked        = $AB;          {block is locked}
  LockCountOverflowed  = $AC;          {lock count overflowed}
  LockFailed           = $AD;          {lock failed}
  SmallerUMBAvailable  = $B0;          {a smaller upper memory block is avail}
  NoUMBAvailable       = $B1;          {no upper memory blocks are available}
  InvalidUMBSegment    = $B2;          {invalid upper memory block segment}

function XmsInstalled : Boolean;
  {-Returns True if an XMS memory manager is installed}

function RequestHMA(Bytes : Word) : Byte;
  {-Request the High Memory Area (HMA). Bytes is amount of memory if TSR or
    device driver, or $FFFF if application program.

    Possible return codes:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $90 if the HMA does not exist
      $91 if the HMA is already in use
      $92 if Bytes is less than the /HMAMIN= parameter
  }

function ReleaseHMA : Byte;
  {-Release the High Memory Area.

    Possible return codes:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $90 if the HMA does not exist
      $93 if the HMA was not allocated
  }

function GlobalEnableA20 : Byte;
  {-Attempt to enable the A20 line. Should be used only by programs that
    have control of the HMA.

    Possible return codes:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $82 if an A20 error occurs
  }

function GlobalDisableA20 : Byte;
  {-Attempt to enable the A20 line. Should be used only by programs that
    have control of the HMA.

    Possible return codes:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $82 if an A20 error occurs
      $94 if the A20 line is still enabled
  }

function LocalEnableA20 : Byte;
  {-Attempt to enable the A20 line. Should be used only by programs that
    need direct access to extended memory.

    Possible return codes:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $82 if an A20 error occurs
  }

function LocalDisableA20 : Byte;
  {-Attempt to enable the A20 line. Should be used only by programs that
    need direct access to extended memory.

    Possible return codes:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $82 if an A20 error occurs
      $94 if the A20 line is still enabled
  }

function QueryA20 : Byte;
  {-Checks to see if the A20 line is physically enabled.

    Possible return codes:
      $00 A20 line disabled
      $01 A20 line enabled
      $80 if the function is not implemented
      $81 if a VDISK device is detected
  }

function QueryFreeExtMem(var TotalFree, LargestBlock : Word) : Byte;
  {-Return the amount of total free extended memory in TotalFree, and the Size
    of the largest free block of extended memory in LargestBlock. Both values
    are specified in number of kilobytes.

    Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $A0 if all extended memory is allocated
  }

function AllocateExtMem(SizeInK : Word; var XmsHandle : Word) : Byte;
  {-Allocate a block of extended memory SizeInK kilobytes in Size, returning
    the XMS handle in XmsHandle.

    Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $A0 if all extended memory is allocated
      $A1 if all extended memory handles are in use
  }

function FreeExtMem(XmsHandle : Word) : Byte;
  {-Free a previously allocated block of extended memory. XmsHandle is the XMS
    handle returned by the previous call to AllocateExtMem.

    Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $A2 if XmsHandle is invalid
      $AB if XmsHandle is currently locked
  }
function MoveExtMemBlock(BlockLength : LongInt;
                         SourceHandle : Word;
                         SourcePtr : ExtMemPtr;
                         DestHandle : Word;
                         DestPtr : ExtMemPtr) : Byte;
  {-Move a block of memory. Intended primarily for moving data to and from
    extended memory and conventional memory. Can also move memory from
    extended to extended and conventional to conventional. BlockLength must
    always be an even number. Memory areas may overlap ONLY if SourcePtr is at
    a lower address than DestPtr. If SourceHandle is 0, then SourcePtr is
    interpreted as a normal segment:offset dword pointer. If SourceHandle is
    non-zero, then the SourcePtr is interpreted as a 32 bit linear offset into
    the extended memory associated with SourceHandle. The same is true for
    DestHandle and DestPtr. This routine does NOT require that the A20 be
    enabled. Extended memory blocks used as SourcePtr or DestPtr need not be
    locked before calling this routine (although they may be locked).

    Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $82 if an A20 error occurs
      $A3 if SourceHandle is invalid
      $A4 if SourcePtr is invalid
      $A5 if DestHandle is invalid
      $A6 if DestPtr is invalid
      $A7 if BlockLen is invalid
      $A8 if SourcePtr and DestPtr contain an invalid overlap
      $A9 if a memory parity error occurs
  }

function LockExtMemBlock(XmsHandle : Word;
                         var LockedBlock : ExtMemPtr) : Byte;
  {-Locks an extended memory block and returns its base address as a 32 bit
    linear address. Locked extended memory blocks are guaranteed not to move.
    The LockedBlock address is valid only while the block is locked. Locked
    extended memory blocks should be unlocked as quickly as possible. It is
    not necessary to lock a block before calling MoveExtMemBlock. A count of
    the number of locks is maintained by the XMS memory manager and can be
    retrieved with the GetHandleInfo function.

    Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $A2 if XmsHandle is invalid
      $AC if the block's lock count overflows
      $AD if the lock fails
  }

function UnlockExtMemBlock(XmsHandle : Word) : Byte;
  {-Unlocks an extended memory block. Any 32 bit linear addresses in use
    obtained by calling LockExtMemBlock are invalid after UnlockExtMemBlock is
    called.

    Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $A2 if XmsHandle is invalid
      $AC if the block's lock count overflows
      $AA if the block is not locked
  }

function GetHandleInfo(XmsHandle : Word;
                       var LockCount    : Byte;
                       var HandlesLeft  : Byte;
                       var BlockSizeInK : Word) : Byte;
  {-Return information about an extended memory handle. The lock count for
    this handle, the number of XMS handles left, and the Size in kilobytes of
    this handle are returned. To retrieve the 32 bit linear address of this
    handle, you must call LockExtMemBlock.

  Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $A2 if XmsHandle is invalid
  }

function ResizeExtMemBlock(XmsHandle : Word; NewSizeInK : Word) : Byte;
  {-Attempts to resize the memory block associated with XmsHandle. The
    extended memory block must be unlocked. If the NewSizeInK is bigger than
    the previous Size, then all data is preserved. If it is smaller, then all
    data beyond the end of the new block Size is lost.

  Possible function results:
      $00 successful
      $80 if the function is not implemented
      $81 if a VDISK device is detected
      $A0 if all extended memory is allocated
      $A1 if all extended memory handles are in use
      $A2 if XmsHandle is invalid
      $AB if the block is locked
  }

function AllocUpperMemBlock(SizeInParas : Word;
                            var SegmentBase : Word;
                            var Size        : Word) : Byte;
  {-Allocates an upper memory block (UMB). If insufficient memory is available
    in upper memory blocks, then the Size of the largest free upper memory
    block is returned in Size. If this functions succeeds, then SegmentBase
    contains the segment of the allocated upper memory block. Upper memory
    blocks are paragraphed aligned (the offset is always 0).

    By definition, UMBs are located below the 1 meg address boundary.
    Therefore the A20 line need not be enabled to access the memory in a UMB.
    Therefore there are no restrictions on using this memory in DOS calls or
    pointing ISRs into this memory.

    This function is not implemented by most 286 XMS drivers. It is
    implemented by most 386 products like QEMM and 386^MAX.

  Possible function results:
      $00 successful
      $80 if the function is not implemented
      $B0 if a smaller UMB is available
      $B1 if no UMBs are available
  }

function FreeUpperMemBlock(SegmentBase : Word) : Byte;
  {-Frees a previously allocated upper memory block.

  Possible function results:
      $00 successful
      $80 if the function is not implemented
      $82 if SegmentBase does not refer to a valid UMB
  }

function XmsErrorString(ErrorCode : Byte) : String;
  {-Return a string indicating reason for error}

  {==========================================================================}

implementation

{ FPC port: stubbed because XMS (INT 2Fh/4300h driver, far-call control
  procedure, HMA, A20 line, UMBs) does not exist on Windows/Linux.
  XmsControl is always Nil and XmsInstalled returns False.  Every XMS call
  returns FuncNotImplemented ($80), which is what an XMS driver reports for an
  unsupported function; output parameters are zeroed.  XmsErrorString is real
  (portable) code. }

  function XmsInstalled : Boolean;
    {-Returns True if an XMS memory manager is installed}
  begin
    { FPC port: stubbed because there is no XMS driver }
    XmsInstalled := XmsControl <> Nil;
  end;

  function RequestHMA(Bytes : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    RequestHMA := FuncNotImplemented;
  end;

  function ReleaseHMA : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    ReleaseHMA := FuncNotImplemented;
  end;

  function GlobalEnableA20 : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    GlobalEnableA20 := FuncNotImplemented;
  end;

  function GlobalDisableA20 : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    GlobalDisableA20 := FuncNotImplemented;
  end;

  function LocalEnableA20 : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    LocalEnableA20 := FuncNotImplemented;
  end;

  function LocalDisableA20 : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    LocalDisableA20 := FuncNotImplemented;
  end;

  function QueryA20 : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    QueryA20 := FuncNotImplemented;
  end;

  function QueryFreeExtMem(var TotalFree, LargestBlock : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    TotalFree := 0;
    LargestBlock := 0;
    QueryFreeExtMem := FuncNotImplemented;
  end;

  function AllocateExtMem(SizeInK : Word; var XmsHandle : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    XmsHandle := 0;
    AllocateExtMem := FuncNotImplemented;
  end;

  function FreeExtMem(XmsHandle : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    FreeExtMem := FuncNotImplemented;
  end;

  function MoveExtMemBlock(BlockLength : LongInt;
                           SourceHandle : Word;
                           SourcePtr : ExtMemPtr;
                           DestHandle : Word;
                           DestPtr : ExtMemPtr) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    MoveExtMemBlock := FuncNotImplemented;
  end;

  function LockExtMemBlock(XmsHandle : Word;
                           var LockedBlock : ExtMemPtr) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    LockedBlock.ProtectedPtr := 0;
    LockExtMemBlock := FuncNotImplemented;
  end;

  function UnlockExtMemBlock(XmsHandle : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    UnlockExtMemBlock := FuncNotImplemented;
  end;

  function GetHandleInfo(XmsHandle : Word;
                         var LockCount    : Byte;
                         var HandlesLeft  : Byte;
                         var BlockSizeInK : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    LockCount := 0;
    HandlesLeft := 0;
    BlockSizeInK := 0;
    GetHandleInfo := FuncNotImplemented;
  end;

  function ResizeExtMemBlock(XmsHandle : Word; NewSizeInK : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver }
    ResizeExtMemBlock := FuncNotImplemented;
  end;

  function AllocUpperMemBlock(SizeInParas : Word;
                              var SegmentBase : Word;
                              var Size        : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver / upper memory }
    SegmentBase := 0;
    Size := 0;
    AllocUpperMemBlock := FuncNotImplemented;
  end;

  function FreeUpperMemBlock(SegmentBase : Word) : Byte;
  begin
    { FPC port: stubbed because there is no XMS driver / upper memory }
    FreeUpperMemBlock := FuncNotImplemented;
  end;

  function HexB(B : Byte) : string;
    {-Return hex string for byte}
  const
    Digits : array[0..$F] of Char = '0123456789ABCDEF';
  begin
    HexB[0] := #2;
    HexB[1] := Digits[B shr 4];
    HexB[2] := Digits[B and $F];
  end;

  function XmsErrorString(ErrorCode : Byte) : String;
    {-Return a string indicating reason for error}
  begin
    case ErrorCode of
      $00 :
        XmsErrorString := 'no XMS error';
      FuncNotImplemented :
        XmsErrorString := 'function not implemented';
      VDiskDeviceDetected :
        XmsErrorString := 'VDISK compatible device detected';
      A20Error :
        XmsErrorString := 'an A20 error occurred';
      GeneralDriverError :
        XmsErrorString := 'general driver error';
      UnrecoverableError :
        XmsErrorString := 'unrecoverable driver error';
      HmaDoesNotExist :
        XmsErrorString := 'high memory area does not exist';
      HmaAlreadyInUse :
        XmsErrorString := 'high memory area already in use';
      HmaSizeTooSmall :
        XmsErrorString := 'size requested less than /HMAMIN= parameter';
      HmaNotAllocated :
        XmsErrorString := 'high memory area not allocated';
      A20StillEnabled :
        XmsErrorString := 'A20 line is still enabled';
      AllExtMemAllocated :
        XmsErrorString := 'all extended memory is allocated';
      OutOfExtMemHandles :
        XmsErrorString := 'extended memory handles exhausted';
      InvalidHandle :
        XmsErrorString := 'invalid handle';
      InvalidSourceHandle :
        XmsErrorString := 'invalid source handle';
      InvalidSourceOffset :
        XmsErrorString := 'invalid source offset';
      InvalidDestHandle :
        XmsErrorString := 'invalid destination handle';
      InvalidDestOffset :
        XmsErrorString := 'invalid destination offset';
      InvalidLength :
        XmsErrorString := 'invalid length';
      OverlapInMoveReq :
        XmsErrorString := 'overlap in move request';
      ParityErrorDetected :
        XmsErrorString := 'parity error detected';
      BlockIsNotLocked :
        XmsErrorString := 'block is not locked';
      BlockIsLocked :
        XmsErrorString := 'block is locked';
      LockCountOverflowed :
        XmsErrorString := 'lock count overflowed';
      LockFailed :
        XmsErrorString := 'lock failed';
      SmallerUMBAvailable :
        XmsErrorString := 'a smaller upper memory block is available';
      NoUMBAvailable :
        XmsErrorString := 'no upper memory blocks are available';
      InvalidUMBSegment :
        XmsErrorString := 'invalid upper memory block segment';
      else
        XmsErrorString := 'unknown XMS error = $' + HexB(ErrorCode);
    end;
  end;

begin
  XmsControl := Nil;  { FPC port: stubbed because there is no XMS driver }
end.
