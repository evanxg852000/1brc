# 1brc implementation

This is my implementation of the one billion row challenge in Zig.
In zig with the basic implementation, it takes about `0.06` seconds. 

```bash
zig build -Doptimize=ReleaseFast
time ./zig-out/bin/1brc 2> output.log 
0.06s user 0.49s system 99% cpu 0.559 total
```

## optimization

- Tweak hashmap
- Try SIMD

