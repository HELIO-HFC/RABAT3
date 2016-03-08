#! /usr/bin/env python
# -*- coding: ASCII -*-

"""
Script to import csv file into a given sqlite table
@author: Xavier Bonnin (CNRS, LESIA)
"""

import sys
import os
import argparse
import sqlite3
import csv

__version__ = "1.0.0"
__license__ = "GPL"
__author__ = "Xavier Bonnin (CNRS, LESIA)"
__credit__ = "Xavier Bonnin"
__maintainer__ = ["Xavier Bonnin", "Christian Renie"]
__email__ = "xavier.bonnin@obspm.fr"
__date__ = "05-MAY-2014"


def csv2sqlite(csv_file, sqlite_file, sqlite_table,
               delimiter=",",
               quotechar="\"", Header=False):

    if not (os.path.isfile(sqlite_file)):
        sys.exit("%s does not exist!", sqlite_file)
    if not (os.path.isfile(csv_file)):
        sys.exit("%s does not exist!", csv_file)

    # Read the csv file
    try:
        with open(csv_file, 'rb') as csvfile:
            content = csv.reader(csvfile,
                                delimiter=delimiter,
                                quotechar=quotechar)

            data = []
            for row in content:
                data.append(row)

    except csv.Error as e:
        sys.exit("Error raised with %s: \n %s"  % (csv_file, e))
    else:
        if (Header):
            data = data[1:]

    # Insert into sqlite
    try:
        conn = sqlite3.connect(sqlite_file)
        c = conn.cursor()
        for i, row in enumerate(data):
            for j, col in enumerate(row):
                if (type(col) == str):
                    data[i][j] = "\"" + col + "\""

            cmd = "INSERT INTO %s VALUES(%s)" % (sqlite_table, ",".join(row))
            print cmd
            c.execute(cmd)
    except sqlite3.Error as e:
        sys.exit("Error raised with %s: \n %s" % (sqlite_file, e))
    else:
        conn.commit()
        conn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
                                     description="Import a csv file into a sqlite table",
                                     add_help=True)
    parser.add_argument("csv_file", nargs=1, help="Path of the csv file")
    parser.add_argument("sqlite_file", nargs=1,
                        help="Path of the sqlite database file")
    parser.add_argument("sqlite_table", nargs=1,
                        help="Table to update in the sqlite table")
    parser.add_argument("-d", "--delimiter", nargs="?",
                        help="Delimiter between values in the csv file",
                        default=",")
    parser.add_argument("-q", "--quotechar", nargs="?",
                        help="Quotechar used in the csv file",
                        default="\"")
    parser.add_argument("-H", "--Header", action="store_true",
                        help="Flag to indicate if the first line of the csv file is the header")

    args = parser.parse_args()
    csv_file = args.csv_file[0]
    sqlite_file = args.sqlite_file[0]
    sqlite_table = args.sqlite_table[0]
    delimiter = args.delimiter
    quotechar = args.quotechar
    Header = args.Header

    csv2sqlite(csv_file, sqlite_file, sqlite_table, delimiter=delimiter,
               quotechar=quotechar, Header=Header)
