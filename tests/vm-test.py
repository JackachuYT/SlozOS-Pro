#!/usr/bin/env python3
"""Boot the SlozOS Pro ISO in QEMU (UEFI, like a Surface Pro 1) and take
screenshots of the boot menu, boot and live desktop.

    vm-test.py <iso> <outdir>
"""
import json, os, shutil, socket, subprocess, sys, tempfile, time

iso, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
tmp = tempfile.mkdtemp()
code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
vars_ = os.path.join(tmp, "vars.fd")
shutil.copy("/usr/share/OVMF/OVMF_VARS_4M.fd", vars_)

qmp_path = os.path.join(tmp, "qmp.sock")
accel = ["-accel", "kvm", "-cpu", "host"] if os.access("/dev/kvm", os.W_OK) else ["-accel", "tcg"]
vm = subprocess.Popen(["qemu-system-x86_64", "-machine", "q35", *accel, "-m", "4096", "-smp", "2",
                       "-drive", f"if=pflash,format=raw,readonly=on,file={code}",
                       "-drive", f"if=pflash,format=raw,file={vars_}",
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
    time.sleep(4);   shot("01-boot-menu.png")
    time.sleep(30);  shot("02-booting.png")
    time.sleep(120); shot("03-desktop.png")
    time.sleep(60);  shot("04-desktop-settled.png")
finally:
    vm.kill()
    shutil.rmtree(tmp, ignore_errors=True)
