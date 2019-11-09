unit module OpenBSD;

use NativeCall;

our sub unveil(Str is encoded('utf8'), Str is encoded('utf8')) returns int32 is native { * }
our sub pledge(Str is encoded('utf8'), Str is encoded('utf8')) returns int32 is native { * }

class X::OpenBSD::Unveil is Exception {
    has $.path;
    has $.return;
    has $.locked;
    method message {
        return "Cannot change $.path, unveil is already locked" if $.locked;
        return "Unveil for $.path failed with return value $.return" if $.path;
        return "Unveil failed with return value $.return";
    }
}

class UnveiledPath {
    has $.path;
    has $.r;
    has $.w;
    has $.x;
    has $.c;
}

module Unveil is export {
    my %paths;
    my $active = False;
    my $locked = False;

    our sub set($path, :$r, :$w, :$x, :$c, :$rw, :$rx, :$rwc) {
        die X::OpenBSD::Unveil.new(path => $path, :locked) if $locked;

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

        my $ret = unveil($abs-path, $permissions);
        die X::OpenBSD::Unveil.new(path => $path, return => $ret) if $ret != 0;

        %paths{$abs-path} = UnveiledPath.new(path => $abs-path.IO, r => $jr, w => $jw, x => $jx, c => $jc);

        $active = True;
    }

    our sub remove($path) {
        set($path);
        %paths{$path.IO.absolute}:delete;
    }

    our sub lock {
        my $ret = unveil(Str, Str);
        die X::OpenBSD::Unveil.new(return => $ret) if $ret != 0;
        $locked = True;
    }

    our sub paths {
        %paths.values;
    }

    our sub locked {
        $locked;
    }

    our sub active {
        $active
    }
}

class X::OpenBSD::Pledge is Exception {
    has $.permission;
    has $.noexsist;
    has $.removed;
    method message {
        return "$.permission is not a valid pledge promise" if $.noexsist;
        return "$.permission cannot be promised, already removed" if $.removed;
        return "Pledge exception";
    }
}

module Pledge is export {
    my $active = False;

    my %permissions =
        :stdio,
        :rpath,
        :wpath,
        :cpath,
        :dpath,
        :tmppath,
        :inet,
        :mcast,
        :fattr,
        :chown,
        :flock,
        :unix,
        :dns,
        :getpw,
        :sendfd,
        :recvfd,
        :tape,
        :tty,
        :proc,
        :exec,
        :prot,
        :settime,
        :ps,
        :vminfo,
        :id,
        :pf,
        :audio,
        :video,
        :bpf,
        :unveil,
        :error;

    my %exec-permissions = %permissions.clone;

    my sub modlist(%permlist, %changes) {
        for %changes.keys -> $key {
            if %permlist{$key}:!exists {
                die X::OpenBSD::Pledge.new(permission => $key, :noexsist);
            }
        }

        my $only = any %changes.values;
        if $only {
            for %permlist.keys -> $key {
                if $key !(elem) %changes {
                    %changes{$key} = False;
                }
            }
        }

        for %changes.kv -> $key, $val {
            if !%permlist{$key} & $val {
                die X::OpenBSD::Pledge.new(permission => $key, :removed);
            }
        }

        for %changes.kv -> $key, $val {
            %permlist{$key} = ?$val;
        }
    }

    my sub genstr(%permlist) {
        %permlist.grep(*.value)>>.key.join(' ');
    }

    our sub set(*%changes) {
        modlist(%permissions, %changes);
        my $perms = genstr(%permissions);
        my $execperms = genstr(%exec-permissions);
        "Reg: $perms\nExec: $execperms";
    }

    our sub set-exec() {
        False;
    }

    our sub permissions {
        Map((self => %permissions.Map,
             exec => %exec-permissions.Map));
    }
}
