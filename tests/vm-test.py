#!/usr/bin/env python3
"""Boot the SlozOS Pro ISO's live desktop in QEMU and take screenshots.

    vm-test.py <iso> <outdir>

Boots casper/vmlinuz + initrd straight from the ISO without "maybe-ubiquity",
so the live desktop shows instead of the Try/Install dialog, then:
  01-boot.png, 02-desktop.png (settled), 03-start.png (Start menu open)
"""
import json, os, shutil, socket, subprocess, sys, tempfile, time

iso, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
tmp = tempfile.mkdtemp()
for f in ("casper/vmlinuz", "casper/initrd.zstd"):
    subprocess.run(["xorriso", "-osirrox", "on", "-indev", iso, "-extract", "/" + f,
                    os.path.join(tmp, os.path.basename(f))], check=True, capture_output=True)

qmp_path = os.path.join(tmp, "qmp.sock")
accel = ["-accel", "kvm", "-cpu", "host"] if os.access("/dev/kvm", os.W_OK) else ["-accel", "tcg"]
vm = subprocess.Popen(["qemu-system-x86_64", "-machine", "q35", *accel, "-m", "6144", "-smp", "4",
                       "-kernel", os.path.join(tmp, "vmlinuz"), "-initrd", os.path.join(tmp, "initrd.zstd"),
                       "-append", "boot=casper quiet splash ---",
                       "-drive", f"file={iso},media=cdrom,readonly=on",
                       "-device", "virtio-vga", "-display", "none",
                       "-device", "qemu-xhci", "-device", "usb-tablet", "-device", "usb-kbd",
                       "-nic", "user,model=virtio-net-pci",
                       "-qmp", f"unix:{qmp_path},server=on,wait=off",
                       "-serial", f"file:{os.path.join(out, 'serial.log')}"])

for _ in range(100):
    if os.path.exists(qmp_path):
        break
    time.sleep(0.2)
s = socket.socket(socket.AF_UNIX); s.connect(qmp_path); f = s.makefile("rw")
def cmd(name, **args):
    f.write(json.dumps({"execute": name, "arguments": args}) + "\n"); f.flush()
    while True:
        msg = json.loads(f.readline())
        if "return" in msg or "error" in msg:
            return msg
f.readline(); cmd("qmp_capabilities")
def shot(name):
    cmd("screendump", filename=os.path.abspath(os.path.join(out, name)), format="png")
    print("  📸", name, flush=True)

try:
    time.sleep(45); shot("01-boot.png")
    time.sleep(150); shot("02-desktop.png")
    cmd("send-key", keys=[{"type": "qcode", "data": "meta_l"}])   # Windows key → Start
    time.sleep(5); shot("03-start.png")
finally:
    vm.kill()
    shutil.rmtree(tmp, ignore_errors=True)
