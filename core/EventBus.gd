extends Node

## EventBus — central signal hub for the whole game.
##
## ARCHITECTURE RULE: components never reference each other directly.
## A component emits a signal here, and any interested component connects
## to it here. That keeps every component isolated and safe to vibe-code
## one at a time without breaking the others.
##
## This file should grow slowly. Only add a signal when the component that
## emits it is actually being built. Do not pre-declare future signals.

# --- Resource / economy signals (Session 1) ---

## Emitted whenever the player's cash changes. Carries the new total.
signal cash_changed(new_amount: int)

## Emitted whenever a tracked resource quantity changes.
## resource_name is one of: "coal", "crush", "blocks".
signal resource_changed(resource_name: String, new_amount: int)
