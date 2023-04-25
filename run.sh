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
        >&2 echo "  lines=$lines, acLines=$actualContentLength, numOfRevs=$numberOfRevisions"
        while read -r rev ; do
            actualContentLengthForRevision="$(yq --yaml-output '.revisions.'"$rev" $file | wc -l)"
            >&2 echo "   look at: $rev with $actualContentLengthForRevision lines"
            echo "$relfile,$actualContentLengthForRevision,$actualContentLength,$lines,$rev,$numberOfRevisions"
        done < <(yq '.revisions | to_entries[] | .key' "$file")
    fi
}



out="stat.csv"

if [[ ! -f "$out" ]]; then
    if [[ ! -f "$out" ]]; then
        echo "file name,length of longest curation,full length of curations,number of lines,revision,number of revisions" > "$out"
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
            statFile "$file" "$relfile" | tee -a "$out"
        fi
    done
fi

cat stat.csv | head -1 > "stat-sorted.csv"
cat stat.csv | tail -n +2 | sort -r -k2 -n -t, >> "stat-sorted.csv"
