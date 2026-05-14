from __future__ import annotations

from datetime import datetime

from .terminal import prepare_for_terminal


class ArabicLogger:
    def __init__(
        self,
        *,
        prefix: str | None = None,
        use_timestamp: bool = False,
        do_reshape: bool = True,
        reorder: bool = True,
        use_lam_alef_ligatures: bool = False,
    ) -> None:
        self._prefix = prefix
        self._use_timestamp = use_timestamp
        self._terminal_opts = {
            'do_reshape': do_reshape,
            'reorder': reorder,
            'use_lam_alef_ligatures': use_lam_alef_ligatures,
        }

    def info(self, message: str) -> None:
        self._log('INFO', message)

    def error(self, message: str) -> None:
        self._log('ERROR', message)

    def warn(self, message: str) -> None:
        self._log('WARN', message)

    def debug(self, message: str) -> None:
        self._log('DEBUG', message)

    def _log(self, level: str, message: str) -> None:
        prepared = prepare_for_terminal(message, **self._terminal_opts)
        line = ''
        if self._use_timestamp:
            line += f'[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}]'
        if self._prefix is not None:
            line += f'[{self._prefix}]'
        line += f'[{level}] {prepared}'
        print(line)


arabic_logger = ArabicLogger()
