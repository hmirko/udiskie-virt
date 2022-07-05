import asyncio
import guestfs
import itertools
import os
import threading
import time

import logging
from .locale import _

from pathlib import Path

__all__ = ['VirtualMount', 'set_virtual_environment']

def set_virtual_environment(debug = False):
    """
    Set environment variables, enabling / disabling debug information
    """
    if debug:
        val = "1"
    else:
        val = "0"

    os.environ["LIBGUESTFS_TRACE"] = val
    os.environ["LIBGUESTFS_DEBUG"] = val

class VirtualMount:
    """Object used to keep track of a virtual mount.

    Each filesystem which is mounted virtually has an associated
    instance of VirtualMount. Due to the behaviour of the libguestfs
    library a thread is spawned. The thread can only be terminate by
    unmounting the mount on the host system (see
    self._mount_path). The unmounting can be done by an external
    programm such as a filemanager or using the tray.


    """
    iterator = itertools.count(start = 0).__next__

    def __init__(self, device_path, label = None):

        self._log = logging.getLogger(__name__)

        self._active = True
        self._id = VirtualMount.iterator()

        if label == None:
            self._label = self._int_to_label(self._id)
        elif len(label) == 0:
            self._label = self._int_to_label(self._id)
        else:
            self._label = label

        self._device_path = device_path
        self._mount_path = '/media/virtmount/' + self._label

        p = Path(self._mount_path)
        p.mkdir(mode = 0o770, parents = True, exist_ok = True)
        self._gfs = guestfs.GuestFS(python_return_dict=True)
#        self._gfs.set_trace(1)
        self._gfs.add_drive_opts(self._device_path,
                                 format="raw",
                                 readonly=0,
                                 label=self._int_to_label(self._id))

        self._gfs.launch()

        devices = self._gfs.list_devices()
        mountable_device = devices[0]
        self._gfs.mount(mountable_device, "/")
        self._gfs.mount_local(self._mount_path)
        self._thread = threading.Thread(target=self.thread_func, args=(1,))
        self._thread.start()

    def _int_to_label(self, i):
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

    def is_active(self):
        return self._active

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

    def stop(self):
        if self._active:
            self.unmount()
            time.sleep(0.1)
            self.deactivate()

    def deactivate(self):
        if self._active:
            self._active = False
            self._gfs.shutdown()
            self._gfs.close()

    def __del__(self):
        if self._active:
            self.deactivate()

    def thread_func(self, args):
        self._gfs.mount_local_run()
        self._log.info(_('virtual mount of {0} at {1} terminated', self._device_path, self._mount_path))
