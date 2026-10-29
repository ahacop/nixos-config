# Printing to the Brother laser on the home wifi: CUPS, the printer queue,
# and the print-text and print-doc commands.
{
  flake.modules.nixos.printing =
    { pkgs, ... }:
    let
      # Shell code for print-text and print-doc. It moves the lp options at the
      # start of the arguments into the lp_args array, and leaves the files in
      # "$@". -n, -d, -o and -P take a value, so the next argument goes with them.
      collectLpArgs = ''
        lp_args=()
        while [ $# -gt 0 ] && [[ "$1" == -* ]]; do
          lp_args+=("$1")
          if [[ "$1" == -[ndoP] ]]; then
            lp_args+=("$2")
            shift
          fi
          shift
        done
      '';
    in
    {
      # CUPS. The printers are declared in hardware.printers, so cups-browsed is
      # off; it would otherwise add a second queue for every printer it finds.
      services.printing = {
        enable = true;
        browsed.enable = false;
        # The PPD for the Brother, made with `driverless cat <device URI>` from
        # cups-filters. It tells CUPS to convert each job to Apple Raster (URF),
        # because the printer reads URF and PWG raster but not PDF. A model of
        # "everywhere" would ask the printer again each time CUPS starts, and
        # CUPS would fail to start while the printer is off.
        drivers = [
          (pkgs.runCommand "brother-hl-l2350dw-ppd" { } ''
            install -Dm644 ${./brother-hl-l2350dw.ppd} $out/share/cups/model/brother-hl-l2350dw.ppd
          '')
        ];
      };

      # The Brother laser on the home wifi. It speaks IPP and needs no vendor
      # driver. The .local name comes from Avahi and survives a new DHCP lease.
      # compression=none stops the CUPS IPP backend from sending gzip. The
      # printer advertises gzip, but it can reject a gzip job partway through
      # with document-format-error and print nothing.
      hardware.printers = {
        ensurePrinters = [
          {
            name = "Brother_HL_L2350DW_series";
            description = "Brother HL-L2350DW";
            deviceUri = "ipp://BRW00410EE401FE.local/ipp/print?compression=none";
            model = "brother-hl-l2350dw.ppd";
            ppdOptions.Duplex = "DuplexNoTumble";
          }
        ];
        ensureDefaultPrinter = "Brother_HL_L2350DW_series";
      };

      environment.systemPackages = with pkgs; [
        # Print text files with the filename, date and page number at the top of
        # each page. paps lays out the text with Pango, so UTF-8 box-drawing
        # characters print; the plain CUPS text filter drops them. Extra lp
        # options go before the files: print-text -n 2 notes.txt
        (writeShellApplication {
          name = "print-text";
          runtimeInputs = [
            coreutils
            cups
            paps
          ];
          text = ''
            ${collectLpArgs}

            if [ $# -eq 0 ]; then
              echo "Usage: print-text [lp options] FILE..." >&2
              exit 1
            fi

            for file in "$@"; do
              paps \
                --format=pdf --paper=a4 --font="Monospace 10" \
                --header --header-left="$(date +%F)" \
                --title="$(basename "$file")" \
                "$file" | lp -t "$(basename "$file")" "''${lp_args[@]}"
            done
          '';
        })

        # Print prose as a typeset document: reflowed paragraphs in Libertinus
        # Serif, with headings and lists. A .md file goes to pandoc as it is.
        # Any other file goes through transcript-to-markdown.awk first, which
        # undoes the 80-column wrap of a Claude Code transcript. Typst sets the
        # type and has the font built in. Extra lp options go before the files:
        # print-doc -n 2 first-pass.txt
        (writeShellApplication {
          name = "print-doc";
          runtimeInputs = [
            coreutils
            cups
            gawk
            pandoc
            typst
          ];
          text = ''
            ${collectLpArgs}

            if [ $# -eq 0 ]; then
              echo "Usage: print-doc [lp options] FILE..." >&2
              exit 1
            fi

            tmp=$(mktemp -d)
            trap 'rm -rf "$tmp"' EXIT

            for file in "$@"; do
              name=$(basename "$file")
              if [[ "$file" == *.md ]]; then
                cp "$file" "$tmp/doc.md"
              else
                awk -f ${./transcript-to-markdown.awk} "$file" > "$tmp/doc.md"
              fi
              pandoc "$tmp/doc.md" -o "$tmp/doc.pdf" \
                --pdf-engine=typst \
                -V papersize=a4 -V margin.x=2.5cm -V margin.y=2.5cm \
                -V mainfont="Libertinus Serif" -V fontsize=11pt
              lp -t "$name" "''${lp_args[@]}" "$tmp/doc.pdf"
            done
          '';
        })
      ];
    };
}
