import sys
import numpy as np
from perlin_noise import PerlinNoise

DEEP_SEA = 0x1E3F5A
SHALLOW_SEA = 0x92C4EE
BEACH = 0xF6E3D4
PLAIN = 0x357A17
FOREST = 0x095429
MOUNTAIN = 0x554124
SNOW = 0xFFFFFF


def get_color(height):
    return (
        DEEP_SEA
        if height < -1
        else SHALLOW_SEA
        if height < 0
        else BEACH
        if height < 0.5
        else PLAIN
        if height < 2
        else FOREST
        if height < 5
        else MOUNTAIN
        if height < 7
        else SNOW
    )


AMPLITUDE = 20
noise1 = PerlinNoise(octaves=3)
noise2 = PerlinNoise(octaves=6)
noise3 = PerlinNoise(octaves=12)
noise4 = PerlinNoise(octaves=24)
assert len(sys.argv) == 2
size = int(sys.argv[1])
with open(f"perlin_{size}x{size}.fdf", "a") as fp:
    for y in np.linspace(0, 1, size):
        row = []
        for x in np.linspace(0, 1, size):
            coords = [y, x]
            height = noise1(coords)
            height += 0.5 * noise2(coords)
            height += 0.25 * noise3(coords)
            height += 0.125 * noise4(coords)
            height *= AMPLITUDE
            row.append(f"{max(0, height):.1f},0x{get_color(height):06x}")
        print(*row, file=fp)
