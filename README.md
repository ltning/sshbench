# SSH client/server benchmark tool

This is a dumb little script that allows you to benchmark a SSH client/server
combination in three ways, for all available or specified Key Exchange
algorithm, MAC and Cipher combinations.

The following benchmarks are supported:
 - Connecting; requires key-based authentication to be set up
 - Sending data; will send 8MB of data to `/dev/null` on the server
 - Receiving data; will receive 8MB of data from `/dev/zero` on the server

It will aggregate results across multiple runs, creating a subdirectory for
each destination system tested and creating/appending to a log file for each
combination of options.

It will then present a table of the results, averaging across the collected
samples for each Kex/MAC/Cipher combination.

## Target audience

People with old and/or slow computers acting as either clients or servers,
who run some flavour of BSD in one or both ends of a connection, and wishes
to know how to configure their SSH server and client for best possible
performance in adverse conditions.

## Platform support
Written for and tested on FreeBSD and NetBSD; it is expected to work on other
BSD flavours and possibly other unices and Linux. I have made no attempt to
be compatible outside Free/Net/OpenBSD, but will be happy to take bug reports.

Requires Bourne Shell - `/bin/sh` - and uses non-POSIX features like `echo -n`
and `local` built-ins. Your mileage with other `sh`-lookalikes may vary.

## Usage
*NOTE:* Key-based authenticatin *must* be set up ahead of time; password
authentication is not supported, nor is it sane for a use-case like this.

Testing using different client and server keys is left as an exercise for
the user.

Basic usage as given by running `bench.sh`:
```
    Usage: ${0} <mode> <destination> [show [<number>]|<iterations>]

    Mode is one of 'connect', 'send' or 'receive'.

    Destination is a host name or IP, optionally prefixed by username@.

    If 'show' is given, benchmarking is skipped and existing results are shown.
    The optional <number> specifies how many of the results are shown; by
    default only the top 10 fastest are displayed.

    Alternatively, if instead of 'show' a number is given for <iterations>,
    the benchmark is run that many times before showing the results. The
    <number> can in this case not be overridden.

    Results shown are an average of all collected results for the given host/mode.
```

## What to test
The included `kex.lst`, `macs.lst` and `ciphers.lst` contain lists of Key
Exchange Algorithms, MACs and Ciphers (respectively) that I typically test
myself. The script will work without those files; it will then run
  ssh -Q kex|macs|ciphers
to build lists of each based on what the *client* supports. Some filters are
applied here; certain weak and "unnecessarily" strong options are removed
to avoid spending a week waiting for my 486 to complete the benchmark.

If used, the automatic detection of options to test makes no attempt to verify
that these are supported by the server. Also, no testing has been done to
determine what happens if you specify - or your client supports - settings
that the server does not accept.

## Example output - Pentium-class server
Using modern hardware as the client, and testing NetBSD's `sshd` on a dual
Pentium Pro 333 MHz, the following seem to be the fastest options (time given
in seconds unless otherwise shown).

### Connecting
```
$ sh bench.sh connect 192.88.99.80 show
Destination   Mode     MAC                            Cipher                         KEX                 Time
192.88.99.80  connect  umac-128-etm@openssh.com       aes128-ctr                     ecdh-sha2-nistp256  1.63
192.88.99.80  connect  umac-64@openssh.com            chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  1.63
192.88.99.80  connect  hmac-sha2-256                  aes128-gcm@openssh.com         ecdh-sha2-nistp256  1.64
192.88.99.80  connect  hmac-sha2-256                  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  1.64
192.88.99.80  connect  hmac-sha1-etm@openssh.com      aes128-gcm@openssh.com         ecdh-sha2-nistp256  1.65
192.88.99.80  connect  hmac-sha2-256                  aes128-ctr                     ecdh-sha2-nistp256  1.65
192.88.99.80  connect  hmac-sha2-256-etm@openssh.com  aes128-ctr                     ecdh-sha2-nistp256  1.65
192.88.99.80  connect  hmac-sha2-256-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  1.66
192.88.99.80  connect  hmac-sha1                      aes128-ctr                     ecdh-sha2-nistp256  1.67
192.88.99.80  connect  hmac-sha1                      aes128-gcm@openssh.com         ecdh-sha2-nistp256  1.67
```

### Sending data
```
$ sh bench.sh send 192.88.99.80 show
Destination   Mode  MAC                            Cipher                         KEX                 Time
192.88.99.80  send  hmac-sha1                      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.39
192.88.99.80  send  umac-64@openssh.com            chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.5
192.88.99.80  send  hmac-sha2-256-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.53
192.88.99.80  send  hmac-sha1-etm@openssh.com      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.56
192.88.99.80  send  hmac-sha2-512-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.56
192.88.99.80  send  umac-128-etm@openssh.com       chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.6
192.88.99.80  send  hmac-sha2-256                  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.65
192.88.99.80  send  umac-128@openssh.com           chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.73
192.88.99.80  send  umac-64-etm@openssh.com        chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.75
192.88.99.80  send  umac-64-etm@openssh.com        aes128-ctr                     ecdh-sha2-nistp256  4.2
```

### Receiving data
```
$ sh bench.sh receive 192.88.99.80 show
Destination   Mode     MAC                            Cipher                         KEX                 Time
192.88.99.80  receive  umac-64-etm@openssh.com        chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.18
192.88.99.80  receive  hmac-sha2-256                  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.29
192.88.99.80  receive  hmac-sha1                      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.3
192.88.99.80  receive  umac-128-etm@openssh.com       chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.3
192.88.99.80  receive  hmac-sha1-etm@openssh.com      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.32
192.88.99.80  receive  hmac-sha2-512-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.38
192.88.99.80  receive  umac-64@openssh.com            chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.39
192.88.99.80  receive  umac-128@openssh.com           chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.4
192.88.99.80  receive  hmac-sha2-256-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  3.62
192.88.99.80  receive  umac-64@openssh.com            aes128-ctr                     ecdh-sha2-nistp256  4.1
```

## Example output - 486-class server
In comparison, results from an AMD Am5x86-P75 (486-class CPU) running at 133 MHz.

### Connecting
```
$ sh bench.sh connect 192.88.99.70 show
Destination   Mode     MAC                            Cipher                         KEX                 Time
192.88.99.70  connect  hmac-sha1                      aes128-gcm@openssh.com         ecdh-sha2-nistp256  4.6
192.88.99.70  connect  hmac-sha2-512-etm@openssh.com  aes128-ctr                     ecdh-sha2-nistp256  4.6
192.88.99.70  connect  umac-128-etm@openssh.com       chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  4.6
192.88.99.70  connect  umac-64@openssh.com            aes128-gcm@openssh.com         ecdh-sha2-nistp256  4.62
192.88.99.70  connect  hmac-sha2-512-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  4.66
192.88.99.70  connect  umac-64-etm@openssh.com        aes128-ctr                     ecdh-sha2-nistp256  4.66
192.88.99.70  connect  hmac-sha1                      aes128-ctr                     ecdh-sha2-nistp256  4.8
192.88.99.70  connect  umac-64-etm@openssh.com        aes128-gcm@openssh.com         ecdh-sha2-nistp256  4.81
192.88.99.70  connect  hmac-sha2-256                  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  5.16
192.88.99.70  connect  hmac-sha1                      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  5.17
```

### Sending data
```
$ sh bench.sh send 192.88.99.70 show
Destination   Mode  MAC                            Cipher                         KEX                 Time
192.88.99.70  send  hmac-sha2-512-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  23.95
192.88.99.70  send  hmac-sha2-256-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  24.03
192.88.99.70  send  hmac-sha1-etm@openssh.com      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  24.11
192.88.99.70  send  hmac-sha1                      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  24.6
192.88.99.70  send  umac-64@openssh.com            chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  25.09
192.88.99.70  send  umac-64-etm@openssh.com        chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  25.42
192.88.99.70  send  umac-128-etm@openssh.com       chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  25.48
192.88.99.70  send  hmac-sha2-256                  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  25.69
192.88.99.70  send  umac-128@openssh.com           chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  25.7
192.88.99.70  send  umac-64@openssh.com            aes128-ctr                     ecdh-sha2-nistp256  27.18
```

### Receiving data
```
$ sh bench.sh receive 192.88.99.70 show
Destination   Mode     MAC                            Cipher                         KEX                 Time
192.88.99.70  receive  hmac-sha1                      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  25.32
192.88.99.70  receive  hmac-sha2-512-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  26.28
192.88.99.70  receive  hmac-sha2-256-etm@openssh.com  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  26.93
192.88.99.70  receive  hmac-sha2-256                  chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  26.94
192.88.99.70  receive  umac-64@openssh.com            chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  27.36
192.88.99.70  receive  umac-128-etm@openssh.com       chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  27.73
192.88.99.70  receive  hmac-sha1-etm@openssh.com      chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  28.24
192.88.99.70  receive  umac-128@openssh.com           chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  28.59
192.88.99.70  receive  umac-64-etm@openssh.com        chacha20-poly1305@openssh.com  ecdh-sha2-nistp256  28.8
192.88.99.70  receive  umac-128-etm@openssh.com       aes128-ctr                     ecdh-sha2-nistp256  28.93
```
