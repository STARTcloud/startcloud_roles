#!/bin/bash
# Rebuilds Mattermost's Posts fulltext indexes with the ngram parser so that
# short tokens and CJK text are searchable. Mattermost's own migrations create
# these indexes with the default parser the first time the server starts, so
# this script has to cope with them being absent as well as present: an
# unguarded DROP INDEX aborts the whole provisioning run on first boot.
# Prints "ngram-index-rebuilt" only when it actually changed something.
set -euo pipefail

db="${1:?usage: alter_db_index.sh <database>}"

posts_table_exists() {
    local count
    count="$(mysql -u root -NBe "SELECT COUNT(*) FROM information_schema.TABLES \
WHERE TABLE_SCHEMA = '${db}' AND TABLE_NAME = 'Posts'")"
    [ "${count}" -gt 0 ]
}

index_exists() {
    local count
    count="$(mysql -u root -NBe "SELECT COUNT(*) FROM information_schema.STATISTICS \
WHERE TABLE_SCHEMA = '${db}' AND TABLE_NAME = 'Posts' AND INDEX_NAME = '${1}'")"
    [ "${count}" -gt 0 ]
}

# information_schema does not expose the fulltext parser, so read it back out of
# the table definition. In batch mode the whole statement arrives on one line, so
# the pattern is bounded to a single index definition.
index_uses_ngram_parser() {
    local pattern
    pattern="FULLTEXT KEY .${1}. \(.${2}.\)[^,]*WITH PARSER .ngram."
    [[ "${posts_definition}" =~ ${pattern} ]]
}

rebuild_ngram_index() {
    local index="$1"
    local column="$2"
    if index_uses_ngram_parser "${index}" "${column}"; then
        return 0
    fi
    if index_exists "${index}"; then
        mysql -u root "${db}" -e "DROP INDEX ${index} ON Posts"
    fi
    mysql -u root "${db}" -e \
        "CREATE FULLTEXT INDEX ${index} ON Posts (${column}) WITH PARSER ngram"
    echo "ngram-index-rebuilt ${index}"
}

if ! posts_table_exists; then
    echo "Posts table is not present in ${db} yet; skipping ngram fulltext index rebuild"
    exit 0
fi

posts_definition="$(mysql -u root -NBe "SHOW CREATE TABLE \`${db}\`.\`Posts\`")"

rebuild_ngram_index idx_posts_message_txt Message
rebuild_ngram_index idx_posts_hashtags_txt Hashtags
