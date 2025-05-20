# scripts/SpriteEntry.gd
extends Resource
class_name SpriteEntry # Makes it selectable in the Inspector

@export var entry_name: String = "" # e.g., "Smoglet" or "Ego"
@export var texture: Texture2D
