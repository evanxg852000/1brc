# 1brc implementation

This is my implementation of the one billion row challenge in Zig.
In zig with the basic implementation, it takes about `0.06` seconds on the 45k dataset. 

```bash
zig build -Doptimize=ReleaseFast
time ./zig-out/bin/1brc 2> output.log 
0.06s user 0.49s system 99% cpu 0.559 total
```

## Generate data

```
gcc create-sample.c -lm -o generate-data
./generate-data 1000000000
```

## Optimization

- Tweak hashmap
- Try SIMD

