#!/usr/bin/env python
"""
Main program runner for Advent of Code 2015 in Python.
This is a series of programming problems available at https://adventofcode.com/2015
"""
from aoc.day01 import Day01
from aoc.day02 import Day02


def day1to5():
    ## Day 1
    print("2015 Day 01 Part 1:", end=" ")
    print(Day01.part1("../inputs/01/input.txt"))
    print("2015 Day 01 Part 2:", end=" ")
    print(Day01.part2("../inputs/01/input.txt"))


def latest():
    print("2015 Day 02 Part 1:", end=" ")
    print(Day02.part1("../inputs/02/input.txt"))
    print("2015 Day 02 Part 2:", end=" ")
    print(Day02.part2("../inputs/02/input.txt"))


def main():
    latest()


if __name__ == "__main__":
    main()
