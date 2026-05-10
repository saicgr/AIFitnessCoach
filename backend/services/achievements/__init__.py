"""Achievements computation: PRs, e1RM, volume, streak, weight trend.

Hooked into the event-log facade so every write that could produce an
achievement (workout / weight / habit / sleep) automatically annotates
the resulting Timeline entry.
"""
