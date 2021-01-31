import os, tables, murmurhash, terminal, docopt

type
    FileTable = Table[
        BiggestInt,
        seq[string]
    ]

    StatusMessage = enum
        smWelcome,
        smReadDir,
        smHashes,
        smReport,
        smIgnoreSize,
        smIgnoreHash

    ErrorMessage = enum
        emDirRead,
        emOutFileExists,
        emOutWrite

# Recursively gets file names and sizes of dir_root
proc readDir(dir_roots: Value): FileTable =
    for dir_root in dir_roots:    
        for file in walkDirRec(dir_root, yieldFilter = {pcFile}):
            let file_size = getFileInfo(file).size
            if file_size > 0:
                if result.hasKey(file_size):
                    result[file_size].add(file)
                else:
                    result[file_size] = @[file]

# Prints out number of files and groups in current file list
proc printSummary(list: FileTable): void =
    var file_count = 0
    for key in keys list:
        file_count += list[key].len()
    setForegroundColor(stdout, fgGreen)
    stdout.write("\b✔")
    resetAttributes()
    echo " Found ", file_count, " files in ", list.len(), " file groups"

# Writes all files and groups into out_file
proc writeAll(list: FileTable, out_file: string): void =
    var o = open(out_file, fmWrite)
    var group_num = 1
    for key in keys list:
        o.write("\n+==> Group #" & $group_num, " has " & $list[key].len() & " duplicate files:\n")
        inc(group_num)
        for file in list[key]:
            o.write("| " & file & "\n")
    o.close()

# Ignores files with unique keys (sizes or hashes depending on when called)
proc ignoreUnique(list_in: FileTable): FileTable =
    for key in keys list_in:
        if list_in[key].len() >= 2:
            result[key] = list_in[key]

# Helper function to hash a file (not to be called directly; call from getFileHashes)
proc hashFile(file_name: string): BiggestInt =
    const buf_size = 16_384
    var
        i: File
        buf = newString(buf_size)
    result = -1.BiggestInt
    if open(i, file_name):
        try:
            while i.readChars(buf, 0, buf_size) > 0:
                let hash = MurmurHash3_x64_128(buf)
                result = result xor (BiggestInt)(hash[0] and hash[1])
        except:
            discard
        finally:
            close(i)
        # echo "  ", file_name, " => ", result


# Gets file hashes for all files in the current list
proc getFileHashes(list_in: FileTable): FileTable =
    for key in keys list_in:
        var file_list = list_in[key]
        for file in file_list:
            var file_hash = hashFile(file)
            if file_hash == -1:
                continue
            if not result.hasKey(file_hash):
                result[file_hash] = @[file]
            else:
                result[file_hash].add(file)

# Prints status messages
proc printStatusMessage(sm: StatusMessage): void =
    let message = case sm:
        of smWelcome: "\nNim Duplicate Files Finder\n\n"
        of smReadDir: "Getting the list of files"
        of smHashes: "Getting file hashes"
        of smReport: "Writing final report"
        of smIgnoreSize: "Ignoring files with unique sizes"
        of smIgnoreHash: "Ignoring files with unique hashes"
    resetAttributes()
    setForegroundColor(stdout, fgCyan)
    if sm != smWelcome:
        stdout.write("Hint: ")
        resetAttributes()
    stdout.write(message)
    stdout.flushFile
    if sm != smWelcome:
        for i in 1..40 - message.len():
            stdout.write(" ")
        stdout.write("⌛")
        stdout.flushFile
    resetAttributes()

# Prints error messages
proc printErrorMessage(em: ErrorMessage): void =
    resetAttributes()
    let message = case em:
        of emDirRead: "Could not read directory"
        of emOutFileExists: "Output file already exists."
        of emOutWrite: "Could not write to output file"
    printStatusMessage(smWelcome)
    setForegroundColor(stdout, fgRed)
    echo "ERROR: " & message
    resetAttributes()
    if em == emOutFileExists:
        setForegroundColor(stdout, fgCyan)
        stdout.write("Hint: ")
        resetAttributes()
        echo "Specify different output file name or force overwrite with --force (-f)"
    quit(1)

# Checks program arguments
proc validArgs(dir_roots: Value, out_file: string, force: bool): bool =
    result = true
    # Source directory should exist and be readable
    for dir_root in dir_roots:
        if not dirExists(dir_root):
            printErrorMessage(emDirRead)
            result = false
    # Output file must not exist
    if fileExists(out_file):
        if force == false:
            printErrorMessage(emOutFileExists)
            result = false
    # Must be able to create and write into the output file
    var o: File
    if open(o, out_file, fmWrite):
        try:
            write(o, "\n")
        except:
            printErrorMessage(emOutWrite)
            result = false
        finally:
            close(o)
    else:
        printErrorMessage(emOutWrite)
        result = false

# Main program
proc main(): void =

    let doc = """

ndf - Nim Duplicate Files Finder
Searches for duplicate files in directories.

Usage:
    ndf [options] -d <dir_root>... -o <out_file>
    ndf (-h | --help)

Options:
    -d <dir_root>, --dir <dir_root>     Directory to scan
                                        You can scan multiple directories
                                        by providing multiple -d switches.
    -o <out_file>, --out <out_file>     Output report file.
    -h --help                           This help message.
    -f --force                          Force overwrite target report file.

Examples:
    ndf --dir /home/user --out duplicates.out
    ndf -d ~/Documents -d ~/Pictures -o report.txt -f

"""

    let args = docopt(doc, version = "0.4.0")

    let dir_root = args["--dir"]
    let out_file = $args["--out"]
    let force = (bool)args["--force"]

    if not validArgs(dir_root, out_file, force):
        quit(1)

    hideCursor()
    printStatusMessage(smWelcome)
    printStatusMessage(smReadDir)
    var files = readDir(dir_root)
    files.printSummary

    printStatusMessage(smIgnoreSize)
    files = files.ignoreUnique
    files.printSummary

    printStatusMessage(smHashes)
    files = files.getFileHashes
    files.printSummary

    printStatusMessage(smIgnoreHash)
    files = files.ignoreUnique
    files.printSummary

    printStatusMessage(smReport)
    files.writeAll(out_file)
    files.printSummary

    showCursor()

main()
