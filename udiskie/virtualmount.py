import asyncio
import guestfs
import itertools
import os
import threading
import time

from pathlib import Path

__all__ = ['VirtualMount', 'set_virtual_environment']

def set_virtual_environment():
    # Set environment
    os.environ["XDG_RUNTIME_DIR"] = "/run/user/1003"
    os.environ["LIBGUESTFS_DEBUG"] = "0"
    os.environ["LIBGUESTFS_TRACE"] = "0"

class VirtualMount:
    """
    Object used to keep track of a virtual mount
    """
    iterator = itertools.count(start = 0).__next__
    def __init__(self, device_path):
        self._active = True
        self._id = VirtualMount.iterator()
        self._label = self.int_to_label(self._id)

        self._device_path = device_path
        self._mount_path = '/media/libguestfs/' + self._label

        p = Path(self._mount_path)
        p.mkdir(mode = 511, parents = True, exist_ok = True)

        self._gfs = guestfs.GuestFS(python_return_dict=True)
#        self._gfs.set_trace(1)
        self._gfs.add_drive_opts(self._device_path,
                                 format="raw",
                                 readonly=0,
                                 label=self._label)
        self._gfs.launch()

        devices = self._gfs.list_devices()
        mountable_device = devices[0]
        self._gfs.mount(mountable_device, "/")
        self._gfs.mount_local(self._mount_path)
        self._thread = threading.Thread(target=self.thread_func, args=(1,))
        self._thread.start()

    def int_to_label(self, i):
        def digit_to_char(d):
            return chr(ord('A') + d)

        label = ""
        initial_value = i
        digits = list()
        d = i % 10
        digits.append(d)
        i = i // 10

        while i > 0:
            d = i % 10
            digits.append(d)
            i = i // 10

        if initial_value > 9:
            digits[-1] = digits[-1] - 1

        chars = list((map(digit_to_char, digits)))

        for c in reversed(chars):
            label = label + c

        return label

    def id(self):
        return self._id

    def label(self):
        return self._label

    def device_path(self):
        return self._device_path

    def mount_path(self):
        return self._mount_path

    def get_thread(self):
        return self._thread

    def unmount(self):
        command = "guestunmount %s" % self._mount_path
        os.popen(command)

    # thread running mount_local_run has lock of gfs handle
    # unmount() terminated the thread
    def deactivate(self):
        self._active = False
        self.unmount()
        time.sleep(0.3)
        self._gfs.shutdown()
        self._gfs.close()

    def __del__(self):
        if self._active:
            self.deactivate()

    def thread_func(self, args):
        self._gfs.mount_local_run()
        print("Virtual mount of %s at %s terminated." % (self._device_path, self._mount_path))
