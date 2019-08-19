#!/usr/bin/env python3

import csv
import json
import sys
import argparse


def csv2dict(csvfile):
    reader = csv.DictReader(csvfile)
    mydict = {}

    for row in reader:
        for field in reader.fieldnames:
            if mydict.get(field) is None:
                mydict.update({field: []})
            mydict[field].append(row.get(field))

    return json.dumps(mydict, indent=2)


def main():
    parser = argparse.ArgumentParser(
        prog="csv2json",
        description="takes a csv file and prints a json representation",
    )
    parser.add_argument(
        "--file",
        "-f",
        help="input csv file (default: stdin)",
        metavar="file.csv",
    )
    args = parser.parse_args()

    if args.file is None:
        print(csv2dict(sys.stdin))
    else:
        with open(args.file) as csvfile:
            print(csv2dict(csvfile))


if __name__ == "__main__":
    main()

# EOF
