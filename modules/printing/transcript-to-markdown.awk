# Turns a Claude Code transcript, hard-wrapped at 80 columns, into pandoc
# Markdown so that pandoc can reflow it. User prompts become block quotes, and
# a short line alone between blank lines in a reply becomes a heading. The
# banner, slash commands and status lines are dropped. Other plain text passes
# through with only the two-space indent removed.
/^ ▐|^▝▜|^ ▝▝|^✻|⎿|^❯ \// { next }
/^❯ / { sub(/^❯ /, ""); mode = "user"; out[++n] = "> " $0; next }
/^● / { sub(/^● /, ""); mode = "bot"; out[++n] = ""; out[++n] = $0; next }
mode == "user" && /^  / { sub(/^  /, ""); out[++n] = "> " $0; next }
{ sub(/^  /, ""); out[++n] = $0; head[n] = (mode == "bot") }
END {
  for (i = 1; i <= n; i++) {
    l = out[i]
    if (head[i] && l != "" && out[i-1] == "" && out[i+1] == "" \
        && l !~ /[.:?!]$/ && l !~ /^([0-9]+\.|-) / && length(l) < 50)
      print "## " l
    else
      print l
  }
}
