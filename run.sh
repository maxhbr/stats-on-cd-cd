#!/usr/bin/env nix-shell
#! nix-shell -i bash -p yq


set -e

statFile() {
    file="$1"
    relfile="$2"
    if [[ -f "$file" ]]; then
        >&2 echo "$relfile:"
        lines="$(wc -l "$file" | awk '{print $1;}')"

        actualContentLength="$(yq --yaml-output '.revisions' $file | wc -l)"
        numberOfRevisions="$(yq '.revisions | length' $file)"
        linesPerRevision="$(echo $((actualContentLength / numberOfRevisions)))" || true
        # if [ $? -ne 0 ]; then
        #     >&2 echo "  division by zero"
        #     # echo "$b is 0 or some other arithmetic error occurred"
        # fi
        >&2 echo "  lines=$lines, acLines=$actualContentLength, numOfRevs=$numberOfRevisions, linesPerRevision=$linesPerRevision"
        echo "$relfile,$lines,$actualContentLength,$numberOfRevisions,$linesPerRevision" >> "$out"
    fi
}



out="stat.csv"

if [[ ! -f "$out" ]]; then
    echo "file name,line count, actual content line count,number of revisions,lines per revision" > "$out"
fi

shopt -s globstar
for file in curated-data/curations/**/*.yaml; do
    relfile="$(realpath --relative-to="curated-data/curations/" "$file")"

    if [[ "$relfile" == *"nuget/nuget/-/PCLCrypto.yaml" ]]; then
        # some files are encoded with ISO-8859, and contain special chars
        # this is not supported by yq
        # e.g.:
        #   curated-data/curations/nuget/nuget/-/PCLCrypto.yaml: ISO-8859 text
        continue
    fi

    if grep -q "$relfile" "$out"; then
        >&2 echo "$relfile: already done"
    else
        statFile "$file" "$relfile"
    fi
done

cat stat.csv | head -1 > "stat-sorted.csv"
cat stat.csv | tail -n +2 | sort -r -k5 -n -t, >> "stat-sorted.csv"
