from __future__ import annotations

import time
from asyncio import Lock
from collections import deque
from typing import Deque, Dict


class RateLimiter:
    """Simple in-memory sliding window rate limiter."""

    def __init__(self, *, max_requests: int, window_seconds: int) -> None:
        self._max_requests = max_requests
        self._window_seconds = window_seconds
        self._requests: Dict[str, Deque[float]] = {}
        self._lock = Lock()

    async def allow(self, key: str) -> bool:
        now = time.monotonic()
        async with self._lock:
            bucket = self._requests.setdefault(key, deque())
            while bucket and now - bucket[0] > self._window_seconds:
                bucket.popleft()

            if len(bucket) >= self._max_requests:
                return False

            bucket.append(now)
            return True

    async def reset(self, key: str) -> None:
        async with self._lock:
            self._requests.pop(key, None)