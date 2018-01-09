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
ndf dir_to_scan output_file
```

## Sample run

> Recursively scan directory `test_files` for duplicate files and save the results in `report.out`. Duplicate files will be grouped together.

```sh
$ ndf test_files report.out

Nim Duplicate File Finder

Getting the list of files               ✔ Found 6 files in 3 file groups
Discarding files with unique sizes      ✔ Found 5 files in 2 file groups
Getting file hashes                     ✔ Found 5 files in 3 file groups
Discarding files with unique hashes     ✔ Found 4 files in 2 file groups
Writing final report                    ✔ Found 4 files in 2 file groups

$ cat report.out
+==> Group: 1 has 2 duplicate files:
| test_files/file1.txt
| test_files/file3d.txt

+==> Group: 2 has 2 duplicate files:
| test_files/.hidden_file
| test_files/a_subdir/file4.dat
```

## Contributing

1. Fork it ( https://github.com/rustomax/ndf/fork )
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request

## Contributors

- [[rustomax]](https://github.com/rustomax) Max Skybin - creator, maintainer
