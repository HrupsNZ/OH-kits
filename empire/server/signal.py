from django.dispatch import Signal


class Dispatcher:
    def __init__(self):
        self.signal = Signal()
        self.connect = self.signal.connect

    def send(self, signal_data, sender=None):
        self.signal.send(sender, signal_data=signal_data)


dispatcher = Dispatcher()
