; --------------------------------------------------------------------------------------------------
;                           msasn1.inc Copyright The MASM32 SDK 1998-2010
; --------------------------------------------------------------------------------------------------

IFNDEF MSASN1_INC
MSASN1_INC equ <1>

ASN1BERDecBitString2 PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecBitString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecBool PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecCharString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecCheck PROTO STDCALL :DWORD,:DWORD
ASN1BERDecDouble PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecEndOfContents PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecEoid PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecExplicitTag PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BERDecFlush PROTO STDCALL :DWORD
ASN1BERDecGeneralizedTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecLength PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecMultibyteString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecNotEndOfContents PROTO STDCALL :DWORD,:DWORD
ASN1BERDecNull PROTO STDCALL :DWORD,:DWORD
ASN1BERDecObjectIdentifier2 PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecObjectIdentifier PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecOctetString2 PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecOctetString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecOpenType2 PROTO STDCALL :DWORD,:DWORD
ASN1BERDecOpenType PROTO STDCALL :DWORD,:DWORD
ASN1BERDecPeekTag PROTO STDCALL :DWORD,:DWORD
ASN1BERDecS16Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecS32Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecS8Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecSXVal PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecSkip PROTO STDCALL :DWORD
ASN1BERDecTag PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecU16Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecU32Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecU8Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecUTCTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecUTF8String PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecZeroChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecZeroChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecZeroCharString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDecZeroMultibyteString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BERDotVal2Eoid PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncBitString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BEREncBool PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BEREncChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BEREncCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BEREncCheck PROTO STDCALL :DWORD,:DWORD
ASN1BEREncDouble PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BEREncEndOfContents PROTO STDCALL :DWORD,:DWORD
ASN1BEREncEoid PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncExplicitTag PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncFlush PROTO STDCALL :DWORD
ASN1BEREncGeneralizedTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncLength PROTO STDCALL :DWORD,:DWORD
ASN1BEREncMultibyteString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncNull PROTO STDCALL :DWORD,:DWORD
ASN1BEREncObjectIdentifier2 PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncObjectIdentifier PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncOctetString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BEREncOpenType PROTO STDCALL :DWORD,:DWORD
ASN1BEREncRemoveZeroBits PROTO STDCALL :DWORD,:DWORD
ASN1BEREncS32 PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncSX PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncTag PROTO STDCALL :DWORD,:DWORD
ASN1BEREncU32 PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncUTCTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREncUTF8String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1BEREncZeroMultibyteString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREoid2DotVal PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1BEREoid_free PROTO STDCALL :DWORD
ASN1CEREncBeginBlk PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1CEREncBitString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1CEREncChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1CEREncChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1CEREncCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1CEREncEndBlk PROTO STDCALL :DWORD
ASN1CEREncFlushBlkElement PROTO STDCALL :DWORD
ASN1CEREncGeneralizedTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1CEREncMultibyteString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1CEREncNewBlkElement PROTO STDCALL :DWORD,:DWORD
ASN1CEREncOctetString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1CEREncUTCTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1CEREncZeroMultibyteString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1DecAbort PROTO STDCALL :DWORD
ASN1DecAlloc PROTO STDCALL :DWORD,:DWORD
ASN1DecDone PROTO STDCALL :DWORD
ASN1DecRealloc PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1DecSetError PROTO STDCALL :DWORD,:DWORD
ASN1EncAbort PROTO STDCALL :DWORD
ASN1EncDone PROTO STDCALL :DWORD
ASN1EncSetError PROTO STDCALL :DWORD,:DWORD
ASN1Free PROTO STDCALL :DWORD
ASN1PERDecAlignment PROTO STDCALL :DWORD
ASN1PERDecBit PROTO STDCALL :DWORD,:DWORD
ASN1PERDecBits PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecBoolean PROTO STDCALL :DWORD,:DWORD
ASN1PERDecChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecCharStringNoAlloc PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecComplexChoice PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecDouble PROTO STDCALL :DWORD,:DWORD
ASN1PERDecExtension PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecFlush PROTO STDCALL :DWORD
ASN1PERDecFragmented PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedExtension PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedIntx PROTO STDCALL :DWORD,:DWORD
ASN1PERDecFragmentedLength PROTO STDCALL :DWORD,:DWORD
ASN1PERDecFragmentedTableChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedTableChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedTableCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedUIntx PROTO STDCALL :DWORD,:DWORD
ASN1PERDecFragmentedZeroChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedZeroChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedZeroCharString PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedZeroTableChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedZeroTableChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecFragmentedZeroTableCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecGeneralizedTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecInteger PROTO STDCALL :DWORD,:DWORD
ASN1PERDecMultibyteString PROTO STDCALL :DWORD,:DWORD
ASN1PERDecN16Val PROTO STDCALL :DWORD,:DWORD
ASN1PERDecN32Val PROTO STDCALL :DWORD,:DWORD
ASN1PERDecN8Val PROTO STDCALL :DWORD,:DWORD
ASN1PERDecNormallySmallExtension PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecObjectIdentifier2 PROTO STDCALL :DWORD,:DWORD
ASN1PERDecObjectIdentifier PROTO STDCALL :DWORD,:DWORD
ASN1PERDecOctetString_FixedSize PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecOctetString_FixedSizeEx PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecOctetString_NoSize PROTO STDCALL :DWORD,:DWORD
ASN1PERDecOctetString_VarSize PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecOctetString_VarSizeEx PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecS16Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecS32Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecS8Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecSXVal PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecSeqOf_NoSize PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecSeqOf_VarSize PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecSimpleChoice PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecSimpleChoiceEx PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecSkipBits PROTO STDCALL :DWORD,:DWORD
ASN1PERDecSkipFragmented PROTO STDCALL :DWORD,:DWORD
ASN1PERDecSkipNormallySmall PROTO STDCALL :DWORD
ASN1PERDecSkipNormallySmallExtension PROTO STDCALL :DWORD,:DWORD
ASN1PERDecSkipNormallySmallExtensionFragmented PROTO STDCALL :DWORD
ASN1PERDecTableChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecTableChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecTableCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecTableCharStringNoAlloc PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecU16Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecU32Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecU8Val PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecUTCTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecUXVal PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PERDecUnsignedInteger PROTO STDCALL :DWORD,:DWORD
ASN1PERDecUnsignedShort PROTO STDCALL :DWORD,:DWORD
ASN1PERDecZeroChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecZeroChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecZeroCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecZeroCharStringNoAlloc PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecZeroTableChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecZeroTableChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecZeroTableCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PERDecZeroTableCharStringNoAlloc PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncAlignment PROTO STDCALL :DWORD
ASN1PEREncBit PROTO STDCALL :DWORD,:DWORD
ASN1PEREncBitIntx PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncBitVal PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncBits PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncBoolean PROTO STDCALL :DWORD,:DWORD
ASN1PEREncChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncCheckExtensions PROTO STDCALL :DWORD,:DWORD
ASN1PEREncComplexChoice PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncDouble PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncExtensionBitClear PROTO STDCALL :DWORD
ASN1PEREncExtensionBitSet PROTO STDCALL :DWORD
ASN1PEREncFlush PROTO STDCALL :DWORD
ASN1PEREncFlushFragmentedToParent PROTO STDCALL :DWORD
ASN1PEREncFragmented PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedIntx PROTO STDCALL :DWORD,:DWORD
ASN1PEREncFragmentedLength PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedTableChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedTableChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedTableCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncFragmentedUIntx PROTO STDCALL :DWORD,:DWORD
ASN1PEREncGeneralizedTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncInteger PROTO STDCALL :DWORD,:DWORD
ASN1PEREncMultibyteString PROTO STDCALL :DWORD,:DWORD
ASN1PEREncNormallySmall PROTO STDCALL :DWORD,:DWORD
ASN1PEREncNormallySmallBits PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncObjectIdentifier2 PROTO STDCALL :DWORD,:DWORD
ASN1PEREncObjectIdentifier PROTO STDCALL :DWORD,:DWORD
ASN1PEREncOctetString_FixedSize PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncOctetString_FixedSizeEx PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncOctetString_NoSize PROTO STDCALL :DWORD,:DWORD
ASN1PEREncOctetString_VarSize PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncOctetString_VarSizeEx PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncOctets PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncRemoveZeroBits PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncSeqOf_NoSize PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncSeqOf_VarSize PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncSimpleChoice PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncSimpleChoiceEx PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncTableChar16String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncTableChar32String PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncTableCharString PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1PEREncUTCTime PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1PEREncUnsignedInteger PROTO STDCALL :DWORD,:DWORD
ASN1PEREncUnsignedShort PROTO STDCALL :DWORD,:DWORD
ASN1PEREncZero PROTO STDCALL :DWORD,:DWORD
ASN1PERFreeSeqOf PROTO STDCALL :DWORD,:DWORD
ASN1_CloseDecoder PROTO STDCALL :DWORD
ASN1_CloseEncoder2 PROTO STDCALL :DWORD
ASN1_CloseEncoder PROTO STDCALL :DWORD
ASN1_CloseModule PROTO STDCALL :DWORD
ASN1_CreateDecoder PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1_CreateDecoderEx PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1_CreateEncoder PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1_CreateModule PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1_Decode PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1_Encode PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ASN1_FreeDecoded PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1_FreeEncoded PROTO STDCALL :DWORD,:DWORD
ASN1_GetDecoderOption PROTO STDCALL :DWORD,:DWORD
ASN1_GetEncoderOption PROTO STDCALL :DWORD,:DWORD
ASN1_SetDecoderOption PROTO STDCALL :DWORD,:DWORD
ASN1_SetEncoderOption PROTO STDCALL :DWORD,:DWORD
ASN1bitstring_cmp PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1bitstring_free PROTO STDCALL :DWORD
ASN1char16string_cmp PROTO STDCALL :DWORD,:DWORD
ASN1char16string_free PROTO STDCALL :DWORD
ASN1char32string_cmp PROTO STDCALL :DWORD,:DWORD
ASN1char32string_free PROTO STDCALL :DWORD
ASN1charstring_cmp PROTO STDCALL :DWORD,:DWORD
ASN1charstring_free PROTO STDCALL :DWORD
ASN1generalizedtime_cmp PROTO STDCALL :DWORD,:DWORD
ASN1intx2int32 PROTO STDCALL :DWORD
ASN1intx2uint32 PROTO STDCALL :DWORD
ASN1intx_add PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1intx_free PROTO STDCALL :DWORD
ASN1intx_setuint32 PROTO STDCALL :DWORD,:DWORD
ASN1intx_sub PROTO STDCALL :DWORD,:DWORD,:DWORD
ASN1intx_uoctets PROTO STDCALL :DWORD
ASN1intxisuint32 PROTO STDCALL :DWORD
ASN1objectidentifier2_cmp PROTO STDCALL :DWORD,:DWORD
ASN1objectidentifier_cmp PROTO STDCALL :DWORD,:DWORD
ASN1objectidentifier_free PROTO STDCALL :DWORD
ASN1octetstring_cmp PROTO STDCALL :DWORD,:DWORD
ASN1octetstring_free PROTO STDCALL :DWORD
ASN1open_cmp PROTO STDCALL :DWORD,:DWORD
ASN1open_free PROTO STDCALL :DWORD
ASN1uint32_uoctets PROTO STDCALL :DWORD
ASN1utctime_cmp PROTO STDCALL :DWORD,:DWORD
ASN1utf8string_free PROTO STDCALL :DWORD
ASN1ztchar16string_cmp PROTO STDCALL :DWORD,:DWORD
ASN1ztchar16string_free PROTO STDCALL :DWORD
ASN1ztchar32string_free PROTO STDCALL :DWORD
ASN1ztcharstring_cmp PROTO STDCALL :DWORD,:DWORD
ASN1ztcharstring_free PROTO STDCALL :DWORD

ELSE
  echo -----------------------------------------
  echo WARNING duplicate include file msasn1.inc
  echo -----------------------------------------
ENDIF
