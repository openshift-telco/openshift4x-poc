#!/bin/env python3

import argparse
import json

__version__ ='0.1.0'

def patch_units(ignition, patch):
    d1 = json.load(open(ignition,'r'))
    d2 = json.load(open(patch,'r'))
    
    d1["systemd"]["units"] += d2["systemd"]["units"]
    
    print (json.dumps(d1))


def main():
    """
    Main entry point
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-i', '--ignition', help='Path to ignition file to use as the base',
        required=True)
    parser.add_argument(
        '-p', '--patch', help='Patch for systemd.units in JSON',
        required=True)
    parser.add_argument(
        '--version', action='version',
        version='%(prog)s {}'.format(__version__))

    args = parser.parse_args()

    patch_units(args.ignition, args.patch)


if __name__ == '__main__':
    main()
