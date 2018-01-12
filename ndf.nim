import os, tables, murmur, streams, strutils, terminal, docopt

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
  var
    list_out = initTable[BiggestInt, seq[string]]()
  for dir_root in dir_roots:  
    for file in walkDirRec dir_root:
      var file_size = getFileInfo(file).size
      if file_size > 0:
        if list_out.hasKey(file_size):
          list_out[file_size].add(file)
        else:
          list_out.add(file_size, @[file])
  result = list_out

# Prints out number of files and groups in current file list
proc printSummary(list: FileTable): void =
  var file_count = 0
  for key in keys list:
    file_count += list[key].len()
  cursorBackward(stdout, 0)
  setForegroundColor(stdout, fgGreen)
  stdout.write("✔")
  resetAttributes()
  echo " Found ", file_count, " files in ", list.len(), " file groups"

# Writes all files and groups into out_file
proc writeAll(list: FileTable, out_file: string): void =
  var o = open(out_file, fmWrite)
  var group_num = 1
  for key in keys list:
    o.write("\n+==> Group # " & $group_num & " (hash:" & $key & ") has " & $list[key].len() & " duplicate files:\n")
    inc(group_num)
    for file in list[key]:
      o.write("| " & file & "\n")
  o.close()

# Ignores files with unique keys (sizes or hashes depending on when called)
proc ignoreUnique(list_in: FileTable): FileTable =
  var list_out = initTable[BiggestInt, seq[string]]()
  result = initTable[BiggestInt, seq[string]]()
  for key in keys list_in:
    if list_in[key].len() >= 2:
      list_out.add(key, list_in[key])
  result = list_out

# Helper function to hash a file (not to be called directly; call from getFileHashes)
proc hashFile(file: string): BiggestInt =
  const buf_size = 16_384
  var
    i: File
    buf = newString(buf_size)
    temp_hash: BiggestInt
  result = BiggestInt(-1)
  if open(i, file):
    try:
      while i.readChars(buf, 0, buf_size) > 0:
        temp_hash = temp_hash xor (BiggestInt)hash(buf)
      result = temp_hash
    except:
      discard
    finally:
      close(i)

# Gets file hashes for all files in the current list
proc getFileHashes(list_in: FileTable): FileTable =
  var list_out = initTable[BiggestInt, seq[string]]()
  for key in keys list_in:
    var file_list = list_in[key]
    for file in file_list:
      var file_hash = hashFile(file)
      if file_hash == -1:
        continue
      if not list_out.hasKey(file_hash):
        list_out.add(file_hash, @[file])
      else:
        list_out[file_hash].add(file)
  result = list_out

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
    if not existsDir(dir_root):
      printErrorMessage(emDirRead)
      result = false
  # Output file must not exist
  if existsFile(out_file):
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
# TODO: More flexible argument handling (allow multiple dir_roots to be analyzed)
proc main(): void =

  let doc = """

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

"""

  let args = docopt(doc, version = "0.2.0")

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
