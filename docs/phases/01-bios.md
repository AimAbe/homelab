# Phase 1 — BIOS Configuration

## Goal

Make the T480 behave like a server: it comes back on its own after power loss, and boots
without a Secure Boot / boot-order fight every time.

## Prerequisites

- Physical access with keyboard + monitor (or the T480's own screen, briefly)

## Steps

1. Reboot and enter BIOS/UEFI setup (Lenovo: `Enter` then `F1`, or `F1` directly at boot).
2. **Power** menu: enable "AC Power Recovery" / "After Power Loss" → set to **Power On**
   (naming varies by firmware version) so the lab survives a breaker trip or outage
   without needing someone to press the power button.
3. **Security** menu: disable **Secure Boot** — Debian's installer and kernel work fine
   either way, but it simplifies driver/module situations later (e.g. for anything that
   needs an unsigned kernel module).
4. **Startup/Boot** menu: set boot order so the USB installer is tried automatically
   (or use the one-time boot menu, typically `F12`, during phase 2's install).
5. Save and exit.

## Verification

- Power the machine off at the wall (or via the power button) and back on — it should
  boot without you touching the keyboard, once phase 2+ is done and it has an OS that
  auto-starts services.
- Confirm Secure Boot shows "Disabled" if you check the setting again.

## Troubleshooting

- **Menu names don't match**: BIOS layouts vary by firmware version — look for
  "Restore on AC/Power Loss" under Power, and "Secure Boot" under Security either way.
- **Machine won't power on after a real outage**: double check the AC Power Recovery
  setting stuck — some firmware resets it after certain updates.
