unit module OpenBSD;

use NativeCall;

our sub unveil(Str is encoded('utf8'), Str is encoded('utf8')) returns int32 is native { * }
our sub pledge(Str is encoded('utf8'), Str is encoded('utf8')) returns int32 is native { * }

class X::OpenBSD::Unveil is Exception {
    has $.path;
    has $.ret-value;
    has $.locked;
    method message {
        return "Cannot change $.path, unveil is already locked" if $.locked;
        return "Unveil for $.path failed with return value $.ret-value" if $.path;
        return "Unveil failed with return value $.ret-value";
    }
}

class UnveiledPath {
    has $.path;
    has $.r;
    has $.w;
    has $.x;
    has $.c;
}

class Unveil {
    has %!paths;
    has $.active = False;
    has $.locked = False;

    method set($path, :$r, :$w, :$x, :$c, :$rw, :$rx, :$rwc) {
        die X::OpenBSD::Unveil.new(path => $path, :locked) if $.locked;

        my $permissions = "";
        my $abs-path = $path.IO.absolute;
        my ($jw, $jr, $jx, $jc) = False, False, False, False;

        if $r | $rw | $rx | $rwc {
            $permissions ~= "r";
            $jr = True;
        }
        if $w | $rw | $rwc {
            $permissions ~= "w";
            $jw = True;
        }
        if $x | $rx {
            $permissions ~= "x";
            $jx = True;
        }
        if $c | $rwc {
            $permissions ~= "c";
            $jc = True;
        }

        my $ret = unveil($path, $permissions);
        die X::OpenBSD::Unveil.new(path => $path, ret-value => $ret) if $ret != 0;

        %!paths{$abs-path} = UnveiledPath.new(path => $abs-path, r => $jr, w => $jw, x => $jx, c => $jc);

        $!active = True;
    }

    method remove($path) {
        self.set($path);
        %!paths{$path.IO.absolute}:delete;
    }

    method lock {
        my $ret = unveil(Str, Str);
        die X::OpenBSD::Unveil.new(ret-value => $ret) if $ret != 0;
        $!locked = True;
    }

    method paths {
        %!paths.values;
    }
}
