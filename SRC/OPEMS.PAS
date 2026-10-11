{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$IFDEF Dpmi}                                                         {!!.20}
  !! This unit cannot be used in protected mode !!                    {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F-,O-,A-}

{$I opdefine.inc}

{*********************************************************}
{*                   OPEMS.PAS 1.30                      *}
{*       Copyright (c) TurboPower Software 1987, 1992.   *}
{* Portions copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpEms;
  {-EMS memory management routines}
  { FPC port: stubbed because EMS (INT 67h) has no equivalent on Windows/Linux;
    the whole interface is kept and reports 'EMS not installed'. }

interface

Uses Dos;                    {!!.03}

const
  EmsErrorCode = $0FFFF;     {Used by several functions to signal an error}

{begin !!.03}
  MaxHandles   = 64;         {maximum number of handles for HandlePagesType}
  {NOTE: Some EMS drivers support up to 255 handles}

  MaxMappablePages = 64;     {maximum number of mappable segments for
                              MappableSegType}
  EmsResult : Byte = 0;      {last EMS error}

type
  PageInfoType =             {used by HandlePagesType type}
    record
      Handle : Word;
      Pages  : Word;
    end;
  HandlePagesType =          {type used by GetPagesForAll}
    record
      NumHandles : Word;
      PageInfo   : Array[1..MaxHandles] of PageInfoType;
    end;
  MappableSegType =          {type used by EMS 4.0 partial mapping routines}
    record
      NumPages : Word;
      Segments : Array[1..MaxMappablePages] of Word;
    end;
  PageMapType =              {type used in PageMapList}
    record
      Logical  : Integer;
      Physical : Word;
    end;
  PageMapList =
    Array[1..MaxMappablePages] of PageMapType; {type used by
                                                MapPagesByNumber and
                                                MapPagesByAddress}
  HandleNameType = Array[1..8] of Char; {native format of EMS handle name}
  HandleNameStr  = String[8];           {TP string format of EMS handle name}
  HandleNameRec  =                      {type used by HandleNameList}
    record
      Handle : Word;
      Name   : HandleNameType;
    end;
  HandleNameList =           {type used by GetAllHandleNames}
    record
      NumNames : Byte;                                  {num names in NameList}
      NameList : Array[1..MaxHandles] of HandleNameRec; {handles and names}
    end;
  MemoryType =
    (Conventional, Expanded); {the two memory type used by EmsPtrRecord}
  EmsPtrRecord =              {used when memory is of type Expanded}
    record
      Offset : Word;
      Page   : Word;
    end;
  EmsPtrType =   {a variant record to represent either a pointer to real or EMS}
    record
      case Boolean of
        False : (ConventionalPtr : Pointer);    {a normal real pointer}
        True  : (ExpandedPtr : EmsPtrRecord);   {a pointer to EMS memory}
    end;
  MoveRecord =   {record structure used internally by MoveMemoryRegion}
    record
      Len               : LongInt;    {number of bytes to move}
      SourceType        : MemoryType; {source memory type}
      SourceHandle      : Word;       {source's EMS handle}
      SourcePtr         : EmsPtrType; {pointer to the source memory}
      DestinationType   : MemoryType; {destination memory type}
      DestinationHandle : Word;       {destination's EMS handle}
      DestinationPtr    : EmsPtrType; {pointer to the destination memory}
    end;
  MappablePageType =   {used in MappablePageList to describe a physical page}
    record
      Segment      : Word;
      PhysicalPage : Word;
    end;
  MappablePageList =   {a list of all mappable pages}
    record
      NumPages : Word;
      Pages    : Array[1..MaxMappablePages] of MappablePageType;
    end;
  HardwareConfigType = {a record of information about the EMS configuration}
    record
      RawPageSize    : Word;    {size of raw EMS pages in paragraphs}
      AltRegSets     : Word;    {number of alternate register sets}
      ContextSize    : Word;    {size of context save area in bytes}
      DMARegSets     : Word;    {number of register sets assignable to DMA}
      DMAOpType      : Word;    {0 = DMA can be used with alternate reg sets
                                 1 = Only one DMA reg set available}
    end;

{end !!.03}

function EmsInstalled : Boolean;
  {-Returns true if the EMM is installed.}

function EmmSigFound : Boolean;
  {-Returns True if EMM signature found}

function EmsStatusOK : Boolean;
  {-Returns true if the EMM reports its status as being OK.}

function EmsPagesAvail : Word;
 {-Returns the number of available pages from the expanded memory manager,
   or EmsErrorCode in case of error.}

function EmsTotalPages : Word;
 {-Returns total number of pages of EMS memory, including allocated pages,
   or EmsErrorCode in case of error.}

function EmsPageFramePtr : Pointer;
  {-Returns the page frame base address as a pointer to the page frame.}

function AllocateEmsPages(NumPages : Word) : Word;
 {-Allocates the indicated number of pages and returns a handle.
   Returns EmsErrorCode in case of error.}

function MapEmsPage(Handle, LogicalPage : Word; PhysicalPage : Byte) : Boolean;
 {-Maps the specified LogicalPage associated with Handle into PhysicalPage
   (0-3). Returns true if successful.}

function DeallocateEmsHandle(Handle : Word) : Boolean;
  {-Deallocates the indicated handle and the memory associated with it.}

function EmsVersion : Byte;
 {-Returns a BCD version number of the EMM handle. To check for version 3.2
   or greater for example, use: 'if EmsVersion >= $32 then'. Returns 0 in
   case of error.}

function SaveEmsContext(Handle : Word) : Boolean;
 {-Saves the EMM context for resident programs. The handle passed must have
   been allocated with a call to AllocateEmsPages. Returns true if
   successful.}

function RestoreEmsContext(Handle : Word) : Boolean;
 {-Restores the mapping context of the EMM driver for the handle specified.
   The handle should the same one used in a prior call to SaveEmsContext.
   Returns true if successful.}

function EmsActiveHandles : Word;
  {-Returns the number of active EMS handles, EmsErrorCode in case of error}

function EmsPagesOwned(Handle : Word) : Word;
  {-Returns the number of pages owned by Handle, or EmsErrorCode in case of error.}

{begin !!.03}
function GetPagesForAll(var HandlePages : HandlePagesType) : Boolean;
  {-Return the number of pages allocated for each active handle.  Function
    result is true if successful in returning the information}

{the following function calls are LIM 3.2 specific (all added !!.03)}

function SavePageMap(var Buffer) : Boolean;
  {-Save the page map to a buffer.  Returns True if successful.  Buffer
    must be at least as big as the value returned by GetSizeOfPageMap.}

function RestorePageMap(var Buffer) : Boolean;
  {-Restore the page map to a buffer.  Returns True if successful.  Buffer
    must contain information obtained by calling SavePageMap.}

function GetSizeOfPageMap : Byte;
  {-Return the size in bytes of the buffer needed to store the page map.
    Returns zero if there is an error.}

{the following function calls are LIM 4.0 specific (all added !!.03)}

function SavePartialPageMap(var MapList : MappableSegType;
                            var Buffer) : Boolean;
  {-Save partial page map into buffer. Returns true if successful. Buffer
    must be at least as big as the value returned by GetSizeOfPartialPageMap
    (given the same number of pages as specified in MapList). Requires EMS
    version 4.0.}

function RestorePartialPageMap(var Buffer) : Boolean;
  {-Restore a partial page map from buffer. Returns True if successful.
    Buffer must have been previously used in a call to SavePartialPageMap.
    Requires EMS version 4.}

function GetSizeOfPartialPageMap(NumPages : Word) : Byte;
  {-Return the size of the buffer needed to save partial page map info for
    NumPages pages. Returns 0 if an error occurs. Requires EMS version 4.}

function MapPagesByNumber(NumPages : Word; Handle : Word;
                          var MappingInfo : PageMapList) : Boolean;
  {-Maps multiple pages by number. NumPages pages are mapped for Handle
    using the information contained within MappingInfo. Returns true if
    successful. If a Logical page number is -1 then the physical page is
    unmapped. The physical field of the PageMapType is used to hold the
    physical page's number. Requires EMS version 4.}

function MapPagesByAddress(NumPages : Word; Handle : Word;
                           var MappingInfo : PageMapList) : Boolean;
  {-Maps multiple pages by Address. NumPages pages are mapped for Handle
    using the information contained within MappingInfo. Returns true if
    successful. If a Logical page number is -1 then the physical page is
    unmapped. The Physical field of the PageMapType is used to hold the
    segment of the page. Requires EMS version 4.}

function ReallocatePages(Handle : Word; NewPages : Word) : Boolean;
  {-Reallocates the number of pages for the specified handle. NewPages may
    be zero (the handle is still active and may be resized later). Returns
    True is successful.}

function GetHandleAttr(Handle : Word; var Volatile : Boolean) : Boolean;
  {-Returns the attribute of the specified handle in Volatile. If Volatile
    is True, then the handle refers to a volatile EMS handle, if false, then
    it is non-volatile (its contents will be maintained across a warm boot).
    Function returns True if successful in returning attribute.}

function SetHandleAttr(Handle : Word; Volatile : Boolean) : Boolean;
  {-Set a handle's attribute. Returns True if successful, False if invalid
    Handle or function not supported. If Volatile is False, and this
    function succeeds, then the contents of the EMS pages allocated to
    Handle will be maintained across a warm boot.}

function AttributeSupported : Boolean;
  {-Returns True if the EMS driver supports the Get/SetHandleAttr functions.}

function GetHandleName(Handle : Word; var Name : HandleNameStr) : Boolean;
  {-Returns the Name of Handle. The name for a handle is set with a call to
    SetHandleName. This function returns True if the name was successfully
    returned. A Handle's name is initialized to the empty string when it is
    allocated or deallocated.}

function SetHandleName(Handle : Word; Name : HandleNameStr) : Boolean;
  {-Set the name of the specified Handle. Returns True if successful.}

function GetAllHandleNames(var List : HandleNameList) : Boolean;
  {-Get the names of all active handles. Returns True as function result if
    successful.}

function SearchForHandleName(Name : HandleNameStr;
                             var Handle : Word) : Boolean;
  {-Search for the specified name and return handle of match if found.
    Returns True as function results if successful. If no match is found,
    function result is false.}

function MoveMemoryRegion(SrcType : MemoryType;
                          SrcHandle : Word;
                          SrcPtr : EmsPtrType;
                          DestType : MemoryType;
                          DestHandle : Word;
                          DestPtr : EmsPtrType;
                          Size : LongInt) : Boolean;
  {-Move a memory region. Returns True as function result if successful.
    Maximum size of region to move is one megabyte. If the length exceeds a
    single page, consecutive pages supply or receive the data. Overlapping
    addresses are handled correctly.

    The type EmsPtrType is used to pass the address of the regions. The
    MemoryType defines how the EmsPtrType is interpreted. If MemoryType
    is Conventional, then the EmsPtrType is interpreted as a regular pointer.
    EmsPtrType is a variant record.  Given the following declarations:

    const
      OurSrcType  : MemoryType = Conventional;
      OurDestType : MemoryType = Expanded;

    var
      OurSrcPtr : EmsPtrType;
      OurDestPtr
      P : Pointer;
      EmsPage : Word;
      EmsOfst : Word;
      EmsHandle : Word;
      OK : Boolean;

    Assume P is pointing to the memory we want to be the source of the move,
    and EmsPage, EmsHandle, and EmsOfst are initialized, then we would do
    the following to call MoveMemoryRegion:

    begin
      OurSrcPtr.ConventionalPtr := P;
      with OurDestPtr.ExpandedPtr do begin
        Offset := EmsOfst;
        Page   := EmsPage;
      end;
      OK := MoveMemoryRegion(OurSrcType, 0, OurSrcPtr, EmsHandle,
                             OurDestType, EmsHandle, OurDestPtr);
    end;
    }

function ExchangeMemoryRegion(SrcType : MemoryType;
                              SrcHandle : Word;
                              SrcPtr : EmsPtrType;
                              DestType : MemoryType;
                              DestHandle : Word;
                              DestPtr : EmsPtrType;
                              Size : LongInt) : Boolean;
  {-Exchange two memory regions. Returns True as function result if
    successful. Parameters have the same meaning as in MoveMemoryRegion. One
    difference is that the memory regions may not overlap in this routine.}

function GetNumberMappablePages : Word;
 {-Return the number of mappable pages.  Returns zero if error.}

function GetAddrMappablePages(var List : MappablePageList) : Boolean;
  {-Return the addresses of all mappable pages. Returns True as function
    result if successful. Will fail if EMS supports more mappable pages
    than the constant MaxMappablePages.}

function GetHardwareConfig(var Config : HardwareConfigType) : Boolean;
  {-Return information about the EMS hardware configuration.  See
    HardwareConfigType definition for description of returned information.
    Returns True as function result if successful.}

function GetNumberOfRawPages(var Total, Free : Word) : Boolean;
  {-Return the number of raw Pages. Returns both the total and the number of
    raw pages free. Returns True as function result if successful. Raw pages
    may have a size other than 16k.}

function EmsErrorMessage(ErrorCode : Byte) : String;
  {-Return an error message for ErrorCode.}

{end !!.03}
  {==========================================================================}

implementation

{ FPC port: stubbed because EMS (INT 67h expanded memory manager) does not
  exist on Windows/Linux.  Every routine behaves exactly as the original does
  when no EMM is installed: EmsInstalled/EmmSigFound return False, Boolean
  routines return False, Word routines return EmsErrorCode, Byte routines
  return 0, EmsPageFramePtr returns nil, and EmsResult is set to
  EmsNotAvailable.  Only EmsErrorMessage is real (portable) code. }

const
  EmsNotAvailable = $80;     {"software malfunction": EMM not present}

  procedure Fail;
  begin
    EmsResult := EmsNotAvailable;
  end;

  function EmsInstalled : Boolean;
    {-Returns true if the EMM is installed.}
  begin
    { FPC port: stubbed because there is no EMM }
    EmsInstalled := False;
  end;

  function EmmSigFound : Boolean;
    {-Returns True if EMM signature found}
  begin
    { FPC port: stubbed because there is no EMM }
    EmmSigFound := False;
  end;

  function EmsStatusOK : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    EmsStatusOK := False;
  end;

  function EmsPagesAvail : Word;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    EmsPagesAvail := EmsErrorCode;
  end;

  function EmsTotalPages : Word;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    EmsTotalPages := EmsErrorCode;
  end;

  function EmsPageFramePtr : Pointer;
  begin
    { FPC port: stubbed because there is no EMM page frame }
    Fail;
    EmsPageFramePtr := nil;
  end;

  function AllocateEmsPages(NumPages : Word) : Word;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    AllocateEmsPages := EmsErrorCode;
  end;

  function MapEmsPage(Handle, LogicalPage : Word; PhysicalPage : Byte) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    MapEmsPage := False;
  end;

  function DeallocateEmsHandle(Handle : Word) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    DeallocateEmsHandle := False;
  end;

  function EmsVersion : Byte;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    EmsVersion := 0;
  end;

  function SaveEmsContext(Handle : Word) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    SaveEmsContext := False;
  end;

  function RestoreEmsContext(Handle : Word) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    RestoreEmsContext := False;
  end;

  function EmsActiveHandles : Word;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    EmsActiveHandles := EmsErrorCode;
  end;

  function EmsPagesOwned(Handle : Word) : Word;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    EmsPagesOwned := EmsErrorCode;
  end;

  function GetPagesForAll(var HandlePages : HandlePagesType) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    HandlePages.NumHandles := 0;
    GetPagesForAll := False;
  end;

  function SavePageMap(var Buffer) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    SavePageMap := False;
  end;

  function RestorePageMap(var Buffer) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    RestorePageMap := False;
  end;

  function GetSizeOfPageMap : Byte;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    GetSizeOfPageMap := 0;
  end;

  function SavePartialPageMap(var MapList : MappableSegType;
                              var Buffer) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    SavePartialPageMap := False;
  end;

  function RestorePartialPageMap(var Buffer) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    RestorePartialPageMap := False;
  end;

  function GetSizeOfPartialPageMap(NumPages : Word) : Byte;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    GetSizeOfPartialPageMap := 0;
  end;

  function MapPagesByNumber(NumPages : Word; Handle : Word;
                            var MappingInfo : PageMapList) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    MapPagesByNumber := False;
  end;

  function MapPagesByAddress(NumPages : Word; Handle : Word;
                             var MappingInfo : PageMapList) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    MapPagesByAddress := False;
  end;

  function ReallocatePages(Handle : Word; NewPages : Word) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    ReallocatePages := False;
  end;

  function GetHandleAttr(Handle : Word; var Volatile : Boolean) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    GetHandleAttr := False;
  end;

  function SetHandleAttr(Handle : Word; Volatile : Boolean) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    SetHandleAttr := False;
  end;

  function AttributeSupported : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    AttributeSupported := False;
  end;

  function GetHandleName(Handle : Word; var Name : HandleNameStr) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    Name := '';
    GetHandleName := False;
  end;

  function SetHandleName(Handle : Word; Name : HandleNameStr) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    SetHandleName := False;
  end;

  function GetAllHandleNames(var List : HandleNameList) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    List.NumNames := 0;
    GetAllHandleNames := False;
  end;

  function SearchForHandleName(Name : HandleNameStr;
                               var Handle : Word) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    SearchForHandleName := False;
  end;

  function MoveMemoryRegion(SrcType : MemoryType;
                            SrcHandle : Word;
                            SrcPtr : EmsPtrType;
                            DestType : MemoryType;
                            DestHandle : Word;
                            DestPtr : EmsPtrType;
                            Size : LongInt) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    MoveMemoryRegion := False;
  end;

  function ExchangeMemoryRegion(SrcType : MemoryType;
                                SrcHandle : Word;
                                SrcPtr : EmsPtrType;
                                DestType : MemoryType;
                                DestHandle : Word;
                                DestPtr : EmsPtrType;
                                Size : LongInt) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    ExchangeMemoryRegion := False;
  end;

  function GetNumberMappablePages : Word;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    GetNumberMappablePages := 0;
  end;

  function GetAddrMappablePages(var List : MappablePageList) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    List.NumPages := 0;
    GetAddrMappablePages := False;
  end;

  function GetHardwareConfig(var Config : HardwareConfigType) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    FillChar(Config, SizeOf(Config), 0);
    GetHardwareConfig := False;
  end;

  function GetNumberOfRawPages(var Total, Free : Word) : Boolean;
  begin
    { FPC port: stubbed because there is no EMM }
    Fail;
    Total := 0;
    Free := 0;
    GetNumberOfRawPages := False;
  end;

  function EmsErrorMessage(ErrorCode : Byte) : String;
    {-Return an error message for ErrorCode.}
  begin
    case ErrorCode of
      $00 : EmsErrorMessage := 'Success';
      $8A : EmsErrorMessage := 'Requested logical page is outside the range of pages owned by handle';
      $8B : EmsErrorMessage := 'Illegal physical page number in mapping request';
      $8C : EmsErrorMessage := 'Page mapping hardware-state save area is full';
      $8D : EmsErrorMessage := 'Context saved failed because save area already contains context for handle';
      $8E : EmsErrorMessage := 'Restore context failed because save area does not contain context for handle';
      $8F : EmsErrorMessage := 'No such subfunction';
      $90 : EmsErrorMessage := 'Attribute type not defined';
      $91 : EmsErrorMessage := 'Feature not supported';
      $92 : EmsErrorMessage := 'Source and destination have same handle and overlap; part of source overwritten';
      $93 : EmsErrorMessage := 'Length for source or destination is longer than actual allocated length';
      $94 : EmsErrorMessage := 'Memory overlaps';
      $95 : EmsErrorMessage := 'Specified offset is outside logical page';
      $96 : EmsErrorMessage := 'Region length exceeds 1 megabyte';
      $97 : EmsErrorMessage := 'Source and destination have same handle and overlap; exhange not performed';
      $98 : EmsErrorMessage := 'Source and destination types are undefined';
      $99 : EmsErrorMessage := '<error code unused>';
      $9A : EmsErrorMessage := 'Specified alternate register set is not supported';
      $9B : EmsErrorMessage := 'All alternate register sets allocated';
      $9C : EmsErrorMessage := 'Register sets not supported, and alternate register set is not zero';
      $9D : EmsErrorMessage := 'Specified alternate register set not defined or allocated';
      $9E : EmsErrorMessage := 'Dedicated DMA channels not supported';
      $9F : EmsErrorMessage := 'Specified dedicated DMA channel not supported';
      $A0 : EmsErrorMessage := 'No handle found for specified name';
      $A1 : EmsErrorMessage := 'Handle with same name already exists';
      $A3 : EmsErrorMessage := 'Invalid pointer passed, or contents of source array corrupted';
      $A4 : EmsErrorMessage := 'Access to function denied by operating system';
      else EmsErrorMessage := 'Unknown EMS error';
    end;
  end;

{$IFDEF InitAllUnits}
begin
{$ENDIF}
end.
