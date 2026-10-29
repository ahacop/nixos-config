# Commands that reach the Mac that runs this VM: notify-macos shows a macOS
# notification, get-dir-sound picks a macOS system sound for the current
# directory, and copy-screenshot copies screenshots from the Mac desktop.
{ inputs, ... }:
{
  flake.modules.nixos.mac-host =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # macOS notification bridge.
        (writeShellScriptBin "notify-macos" ''
          export MACOS_HOST_IP="''${MACOS_HOST_IP:-chunky-peanut-butter.local}"
          exec ${
            inputs.macos-notifier-bridge.packages.${pkgs.stdenv.hostPlatform.system}.notify-macos
          }/bin/notify-macos "$@"
        '')
        # Get macOS system sound based on current directory
        (writeShellApplication {
          name = "get-dir-sound";
          runtimeInputs = [ coreutils ];
          text = ''
            # Get the current directory name
            DIR_NAME=$(basename "$PWD")

            # List of available macOS system sounds
            SOUNDS=(
              "Basso"
              "Blow"
              "Bottle"
              "Frog"
              "Funk"
              "Glass"
              "Hero"
              "Morse"
              "Ping"
              "Pop"
              "Purr"
              "Sosumi"
              "Submarine"
              "Tink"
            )

            # Hash the directory name and map to a sound
            HASH=$(echo -n "$DIR_NAME" | sha256sum | cut -d' ' -f1)
            # Convert first 8 hex chars to decimal and modulo by number of sounds
            INDEX=$(( 0x''${HASH:0:8} % ''${#SOUNDS[@]} ))
            echo "''${SOUNDS[$INDEX]}"
          '';
        })

        # Copy latest screenshot(s) from Desktop to current directory
        (writeShellApplication {
          name = "copy-screenshot";
          runtimeInputs = [
            coreutils
            findutils
          ];
          text = ''
            DESKTOP_PATH="/host/ahacop/Desktop"
            NUM_SCREENSHOTS="''${1:-1}"

            # Validate the argument is a positive integer
            if ! [[ "$NUM_SCREENSHOTS" =~ ^[0-9]+$ ]] || [ "$NUM_SCREENSHOTS" -lt 1 ]; then
              echo "Error: Argument must be a positive integer" >&2
              echo "Usage: copy-screenshot [N]" >&2
              exit 1
            fi

            # Check if Desktop directory exists
            if [ ! -d "$DESKTOP_PATH" ]; then
              echo "Error: Desktop directory not found at $DESKTOP_PATH" >&2
              exit 1
            fi

            # Find screenshots and sort by modification time (newest first)
            # Screenshot filenames look like: "Screenshot 2025-11-30 at 5.31.47 PM.png"
            mapfile -t screenshots < <(find "$DESKTOP_PATH" -maxdepth 1 -type f -name "Screenshot *.png" -printf '%T@ %p\n' | sort -rn | head -n "$NUM_SCREENSHOTS" | cut -d' ' -f2-)

            # Check if any screenshots were found
            if [ ''${#screenshots[@]} -eq 0 ]; then
              echo "No screenshots found in $DESKTOP_PATH" >&2
              exit 1
            fi

            # Check if we found fewer screenshots than requested
            if [ ''${#screenshots[@]} -lt "$NUM_SCREENSHOTS" ]; then
              echo "Warning: Only found ''${#screenshots[@]} screenshot(s), requested $NUM_SCREENSHOTS" >&2
            fi

            # Copy each screenshot to current directory
            for screenshot in "''${screenshots[@]}"; do
              filename=$(basename "$screenshot")
              cp -v "$screenshot" "./$filename"
            done

            echo "Copied ''${#screenshots[@]} screenshot(s) to current directory"
          '';
        })
      ];
    };
}
