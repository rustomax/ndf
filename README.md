# ndf

Command line utility written in [Nim](https://nim-lang.org/) to find duplicate files. This program does not delete any files. It generates a list of duplicates in a specific directory for you to review and deal with them as you see fit.

It is written to be acceptably fast and memory-efficient on modern hardware. Analyzing a directory of over 500,000 files of various sizes and types takes roughly 5 minutes and uses ~200MB RAM on my mid 2015 MacBook Pro.

So far `ndf` has been tested on OSX only. It *should* work on Linux and Windows as well.

## Install with nimble

```sh
nimble install ndf
```

Nimble will install `ndf` into `~/.nimble/pkgs/ndf-<version>/`. To install `ndf` system-wide copy the binary it into a `bin` folder in your path, i.e.

```sh
cp ~/.nimble/pkgs/ndf-0.1.0/ndf /usr/local/bin/
```

## Install from source

```sh
git clone https://github.com/rustomax/ndf.git
cd ndf
nimble install murmur
nim compile -d:release -o:ndf ndf.nim
```

To install `ndf` system-wide copy the binary it into a `bin` folder in your path, i.e.

```sh
cp ndf /usr/local/bin/
```

## Usage

```sh
$ ndf -h
ndf - Nim Duplicate Files Finder
Searches for duplicate files in directories.

Usage:
  ndf [options] -d <dir_root>... -o <out_file>
  ndf (-h | --help)

Options:
  -d <dir_root>, --dir <dir_root>   Directory to scan. (Directory must exist and be readable)
                                    You can scan multiple directories by providing multiple -d switches.
  -o <out_file>, --out <out_file>   Output report file.
  -h --help                         This help message.
  -f --force                        Force overwrite target report file.

Examples:
  ndf --dir /home/user --out duplicates.out
  ndf -d ~/Documents -d ~/Pictures -o report.txt -f
```

## Sample run

> Recursively scan directory `test_files` for duplicate files and save the results in `report.out`. Duplicate files will be grouped together.

```sh
$ ndf -d test_files/ -o report.out

Nim Duplicate Files Finder

Hint: Getting the list of files               ✔ Found 6 files in 3 file groups
Hint: Ignoring files with unique sizes        ✔ Found 5 files in 2 file groups
Hint: Getting file hashes                     ✔ Found 5 files in 3 file groups
Hint: Ignoring files with unique hashes       ✔ Found 4 files in 2 file groups
Hint: Writing final report                    ✔ Found 4 files in 2 file groups
```

## Contributing

1. [Fork it](https://github.com/rustomax/ndf/fork)
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request

## Contributors

- [[rustomax]](https://github.com/rustomax) Max Skybin - creator, maintainer
