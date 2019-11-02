unit module OpenBSD;

use NativeCall;

our sub unveil(Str is encoded('utf8'), Str is encoded('utf8')) returns int32 is native is export { * }

our sub pledge(Str is encoded('utf8'), Str is encoded('utf8')) returns int32 is native is export { * }
