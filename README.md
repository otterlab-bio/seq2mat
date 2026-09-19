# seq2mat

**A standalone Go converter from HTSeq count files to traceable expression matrices.**

`seq2mat` merges per-sample HTSeq outputs, maps identifiers to gene symbols using an embedded database, aggregates repeated symbols, and writes count and log2-normalized matrices without an R runtime (release and normal source builds embed the mapping CSVs; R/Rscript is only needed to regenerate them from the upstream .rda sources).

## Quick start

```bash
git clone https://github.com/otterlab-bio/seq2mat.git
cd seq2mat
go build -o seq2mat ./cmd/seq2mat

./seq2mat \
  --htseq_dir /analysis/htseq \
  --output_dir /analysis/matrix
```

For mouse inputs, select the matching file suffix:

```bash
seq2mat \
  --htseq_dir /analysis/htseq \
  --postfix "_mouse.txt" \
  --output_dir /analysis/matrix
```

## Proof

A real conversion writes both matrices plus a manifest recording exactly how they were derived
(excerpted):

```text
$ seq2mat --htseq_dir /analysis/htseq --output_dir /analysis/matrix
$ ls /analysis/matrix
matrix_count.txt  matrix_norm.txt  matrix_manifest.json

$ head -20 matrix_manifest.json
{
  "schema_version": "seq2mat.matrix/1.0.0",
  "generator_version": "0.1.0",
  "species": "human",
  "postfix": "_human.txt",
  "sample_count": 2,
  "row_count": 4,
  "mapping": {
    "schema_version": "seq2mat.mapping/1.0.0",
    "source": "embedded:gene_mapping_human.csv",
    "source_sha256": "1cee427e899c0d01851441a0609d8696113a7b0a4cf849110ee093714bc79f09",
    "input_id_count": 39839
  }
}
```

The mapping digest is the part that matters downstream: it pins which embedded database produced the
symbols, so two matrices generated months apart can be shown to have used the same mapping.

## Input contract

- `--htseq_dir` is required and contains per-sample HTSeq output files.
- `--postfix` selects the input filename suffix; the default is `_human.txt`.
- `--species` forces `human` or `mouse`; when omitted it is detected from `--postfix`.
- `--output_dir` is required.
- Gene mapping assets are embedded in release binaries. Custom mapping files are a source-build/development concern.

## Output contract

```text
matrix_count.txt       raw count matrix
matrix_norm.txt        log2(x + 1) matrix
matrix_manifest.json   mapping source, parameters, and conversion statistics
```

Outputs are TSV files with gene symbols in the first column and sample IDs in the remaining columns. The manifest uses the versioned `seq2mat.matrix/1.0.0` and `seq2mat.mapping/1.0.0` schemas. These are `seq2mat` schemas; HTSeq describes the input format, not the output schema.

## Processing model

1. Select files by suffix.
2. Left-join samples by gene identifier.
3. Map identifiers to symbols using the embedded human or mouse database.
4. Aggregate repeated symbols by maximum value.
5. Remove zero, `NA`, and `-Inf` rows.
6. Write raw and log2-normalized matrices plus a manifest.

## Cross-compilation

```bash
GOOS=linux GOARCH=amd64 go build -o seq2mat-linux ./cmd/seq2mat
GOOS=darwin GOARCH=arm64 go build -o seq2mat-macos-arm64 ./cmd/seq2mat
GOOS=windows GOARCH=amd64 go build -o seq2mat-windows.exe ./cmd/seq2mat
```

## Development

```bash
gofmt -w .
go test ./...
go vet ./...
```

## Continuous integration

`.github/workflows/ci.yml` runs on `push`, `pull_request`, and manual dispatch. It checks
`gofmt -l`, runs `go vet` and the full test suite, builds the binary, and then runs a
deterministic HTSeq-to-matrix contract smoke with the embedded mapping database. The
smoke asserts the count matrix, the log2-normalized matrix, and the
`seq2mat.matrix/1.0.0` / `seq2mat.mapping/1.0.0` manifest fields. Logs and produced
matrices are uploaded as the `seq2mat-matrix-evidence` artifact, including on failure.

The tool intentionally writes TSV rather than RDS/RData output. R can read the matrices with `read.delim()` or equivalent readers.

## License and repository

MIT · [otterlab-bio/seq2mat](https://github.com/otterlab-bio/seq2mat)
