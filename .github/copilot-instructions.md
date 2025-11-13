# icandoit1 Copilot Guide

## Overview
- Godot 4.5 2D project; configuration lives in `project.godot` and currently no `run/main_scene` is defined, so expect to wire one up when gameplay is added.
- Core content sits under `World/`, split into `Characters/` for controllable actors and `Maps/` for playable scenes.
- This repo is intentionally minimal right now; keep contributions focused and self-contained so the Godot editor stays the source of truth for scene wiring.

## Scenes and Scripts
- Each gameplay element pairs a `.tscn` scene with a sibling `.gd` script (`World/Characters/player.tscn` ↔ `World/Characters/player.gd`). Follow the same layout for new actors or props.
- Scenes are saved in text format with stable `uid` entries; let the Godot editor regenerate them instead of hand-editing to avoid mismatched resource IDs.
- Godot 4 sidecar files like `player.gd.uid` are committed; do not delete them when renaming scripts, since other scenes rely on the UID mapping.

## Coding Patterns
- Scripts extend built-in 2D classes (e.g. `CharacterBody2D` in `player.gd`). When adding movement or physics, prefer `_physics_process(delta)` and `move_and_slide()` to stay consistent with Godot defaults.
- Use exported variables for any scene-tunable data so designers can tweak values in the editor without touching code.
- Favor signals for cross-node communication; connect them in scenes to keep logic decoupled from node paths.

## Workflow Tips
- Launch the editor with `godot4 --path . --editor` (or double-click the project file) to edit scenes; run the game with `godot4 --path .` once a main scene is configured.
- The `.godot/` cache is ignored by Git except for metadata Godot insists on keeping; you can safely clear it locally if the editor misbehaves.
- Keep assets in `res://` relative paths; Godot expects forward slashes even on Windows.

## Source Control
- `.gitattributes` forces LF endings; avoid introducing CRLF manually when editing outside Godot.
- `.gitignore` already excludes generated platform folders and most editor cache; add new ignores only if Godot cannot regenerate the files automatically.

## When Adding Features
- Start by duplicating `World/Maps/Map1.tscn` or creating a fresh scene, then attach scripts directly from the Godot editor so UID files update correctly.
- After scripting, open the scene in the editor to ensure serialized node paths and property lists are consistent before committing.
- If you introduce input events, register them under Project Settings → Input Map and mention the action name in code comments for clarity.
