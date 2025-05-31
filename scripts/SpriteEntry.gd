# scripts/SpriteEntry.gd
extends Resource
class_name SpriteEntry # Makes it selectable in the Inspector

@export var entry_name: String = "" # e.g., "Smoglet" or "Ego"
@export var front_texture: Texture2D # Front sprite texture (for opponent's Unamon)
@export var back_texture: Texture2D # Back sprite texture (for player's Unamon)
@export var cry_sound: AudioStream # The unique cry sound for this Unamon
