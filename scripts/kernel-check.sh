#!/usr/bin/env bash
#
# Saves a snapshot of system load to ~/kernel-checks, so a slow VM can be
# compared with a normal one. Run it once while the VM feels normal and again
# while it feels slow, then diff the two files.
#
# The snapshot holds the kernel version, load, CPU and IO pressure, the
# busiest processes, the interrupts that fire most over 10 seconds, vmstat
# output, and the log messages that repeat most in the last hour. A driver
# that floods the log or fires interrupts without pause shows up at the top
# of those two lists.
#
# The run takes about 15 seconds, because the interrupt and vmstat samples
# wait in real time. The journal keeps 3 days of logs, so a check that runs
# later than that after a slowdown finds no log messages from it.

# No pipefail: most pipelines end in head, which closes the pipe early and
# makes the command before it exit with SIGPIPE.
set -eu

INTERRUPT_SECONDS=10

dir="$HOME/kernel-checks"
mkdir -p "$dir"
out="$dir/$(uname -r)-$(date +%Y%m%d-%H%M%S).txt"

# Sums the per-CPU counts on each line of /proc/interrupts and prints
# "count<TAB>name", where name is the IRQ number and its description.
interrupt_totals() {
  awk 'NR == 1 { ncpu = NF; next }
       {
         total = 0
         for (i = 2; i <= ncpu + 1 && i <= NF; i++) total += $i
         name = $1
         for (i = ncpu + 2; i <= NF; i++) name = name " " $i
         print total "\t" name
       }' /proc/interrupts
}

section() {
  printf '\n== %s\n' "$1"
}

{
  section "Kernel and uptime"
  uname -r
  uptime

  section "CPU, IO and memory pressure (avg10 is the share of the last 10s that tasks waited)"
  for res in cpu io memory; do
    printf '%s: %s\n' "$res" "$(head -1 /proc/pressure/$res)"
  done

  # A thread that waits on io_uring counts as IO wait in the pressure and
  # vmstat numbers, even when no disk IO happens. Ghostty keeps two such
  # threads, so this list shows how much of the IO wait is real.
  section "Threads in IO wait: D state, or waiting on io_uring"
  for t in /proc/[0-9]*/task/[0-9]*; do
    state=$(awk '{ print $3 }' "$t/stat" 2>/dev/null) || continue
    wchan=$(cat "$t/wchan" 2>/dev/null) || continue
    if [ "$state" = D ] || [ "$wchan" = io_cqring_wait ]; then
      printf '%s %s %s %s\n' "${t#/proc/}" "$state" "$wchan" "$(cat "$t/comm" 2>/dev/null)"
    fi
  done

  section "Memory"
  free -h

  section "Top 10 processes by CPU"
  ps -eo pid,pcpu,pmem,etime,comm --sort=-pcpu | head -11

  section "Interrupts per second, top 10, over ${INTERRUPT_SECONDS}s"
  before=$(interrupt_totals)
  sleep "$INTERRUPT_SECONDS"
  after=$(interrupt_totals)
  awk -F '\t' -v secs="$INTERRUPT_SECONDS" \
    'NR == FNR { start[$2] = $1; next }
     { printf "%10.0f  %s\n", ($1 - start[$2]) / secs, $2 }' \
    <(printf '%s\n' "$before") <(printf '%s\n' "$after") |
    sort -rn | head -10

  section "vmstat, 5 samples 1s apart (wa is IO wait, si/so is swap)"
  vmstat 1 5

  section "Log lines in the last hour"
  journalctl --since=-1h --no-pager -q -o cat | wc -l

  section "Top 15 repeated log messages in the last hour (numbers masked as N)"
  journalctl --since=-1h --no-pager -q -o cat |
    sed -E 's/[0-9]+/N/g' | sort | uniq -c | sort -rn | head -15

  section "Kernel warnings and errors this boot, last 20"
  journalctl -k -b -p warning --no-pager -q -o short-monotonic | tail -20
} >"$out" 2>&1

echo "Saved $out"
