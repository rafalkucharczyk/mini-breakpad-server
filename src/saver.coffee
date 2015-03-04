fs = require 'fs-plus'
path = require 'path'
mkdirp = require 'mkdirp'
Record = require './record'
formidable = require 'formidable'

exports.saveDump = (req, db, callback) ->
  Record.createFromRequest req, (err, record) ->
    return callback new Error("Invalid breakpad request") if err?

    dist = "pool/files/minidump"
    mkdirp dist, (err) ->
      return callback new Error("Cannot create directory: #{dist}") if err?

      filename = path.join dist, record.id
      fs.copy record.path, filename, (err) ->
        return callback new Error("Cannot create file: #{filename}") if err?

        record.path = filename
        db.saveRecord record, (err) ->
          return callback new Error("Cannot save record to database") if err?

          callback null, filename

exports.saveSymbol = (req, db, callback) ->
  dist = "pool/symbols"
  form = new formidable.IncomingForm()
  form.parse req, (error, fields, files) ->
    unless files.symbol_file?.name?
      return callback new Error('Invalid breakpad upload')

    src_file = files.symbol_file.path;
    dst_dir = path.join dist, fields.debug_file, fields.debug_identifier

    mkdirp dst_dir, (err) ->
      return callback new Error("Cannot create directory: #{dst_dir}") if err?

      dst_file = path.join dst_dir, fields.debug_file + ".sym"

      fs.copy src_file, dst_file, (err) ->
        return callback new Error("Cannot create file: #{filename}") if err?

      callback(null, dst_file)
