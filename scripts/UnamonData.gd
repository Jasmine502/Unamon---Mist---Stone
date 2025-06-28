# scripts/UnamonData.gd
extends Node

enum TYPES { NORMAL, FIRE, WATER, GRASS, ELECTRIC, ICE, FIGHTING, FLYING, GHOST, DRAGON, BUG, GROUND, PSYCHIC, ROCK, POISON, STEEL, DARK, FAIRY }
enum MOVE_CATEGORY { PHYSICAL, SPECIAL }

const UNAMON_DATABASE = {
	"Smoglet": {
		"types": [TYPES.FIRE, TYPES.GHOST],
		"base_stats": {"VIT": 40, "STR": 30, "RES": 30, "ESS": 70, "SPI": 50, "AGI": 60},
		"moves": ["Ember", "Astonish", "Shadow Sneak", "Flame Burst"]
	},
	"Flamura": {
		"types": [TYPES.FIRE, TYPES.GHOST],
		"base_stats": {"VIT": 50, "STR": 40, "RES": 40, "ESS": 85, "SPI": 60, "AGI": 80},
		"moves": ["Flame Wheel", "Shadow Ball", "Hex", "Incinerate"]
	},
	"Ignantom": {
		"types": [TYPES.FIRE, TYPES.GHOST],
		"base_stats": {"VIT": 70, "STR": 65, "RES": 60, "ESS": 110, "SPI": 70, "AGI": 95},
		"moves": ["Flamethrower", "Phantom Force", "Inferno", "Ominous Wind"]
	},
	"Flopix": {
		"types": [TYPES.WATER, TYPES.FLYING],
		"base_stats": {"VIT": 40, "STR": 30, "RES": 35, "ESS": 55, "SPI": 40, "AGI": 70},
		"moves": ["Water Gun", "Gust", "Bubble", "Wing Attack"]
	},
	"Aquilia": {
		"types": [TYPES.WATER, TYPES.FLYING],
		"base_stats": {"VIT": 55, "STR": 50, "RES": 50, "ESS": 75, "SPI": 55, "AGI": 90},
		"moves": ["Water Pulse", "Aerial Ace", "Aqua Jet", "Air Cutter"]
	},
	"Marinawk": {
		"types": [TYPES.WATER, TYPES.FLYING],
		"base_stats": {"VIT": 70, "STR": 70, "RES": 65, "ESS": 100, "SPI": 70, "AGI": 115},
		"moves": ["Hydro Pump", "Hurricane", "Aqua Tail", "Sky Attack"]
	},
	"Cracklesap": {
		"types": [TYPES.GRASS, TYPES.ELECTRIC],
		"base_stats": {"VIT": 50, "STR": 55, "RES": 45, "ESS": 50, "SPI": 40, "AGI": 40},
		"moves": ["Vine Whip", "Thunder Shock", "Razor Leaf", "Spark"]
	},
	"Salamendro": {
		"types": [TYPES.GROUND, TYPES.ELECTRIC],
		"base_stats": {"VIT": 70, "STR": 85, "RES": 70, "ESS": 60, "SPI": 60, "AGI": 75},
		"moves": ["Bulldoze", "Thunder Fang", "Dig", "Discharge"]
	},
	"Wyvorophyll": {
		"types": [TYPES.GRASS, TYPES.DRAGON],
		"base_stats": {"VIT": 100, "STR": 80, "RES": 90, "ESS": 110, "SPI": 100, "AGI": 50},
		"moves": ["Giga Drain", "Dragon Breath", "Energy Ball", "Dragon Pulse"]
	},
	"Cryoul": {
		"types": [TYPES.ICE, TYPES.GHOST],
		"base_stats": {"VIT": 30, "STR": 30, "RES": 30, "ESS": 75, "SPI": 45, "AGI": 70},
		"moves": ["Ice Shard", "Lick", "Icy Wind", "Night Shade"]
	},
	"Cryophant": {
		"types": [TYPES.ICE, TYPES.GHOST],
		"base_stats": {"VIT": 80, "STR": 60, "RES": 70, "ESS": 90, "SPI": 75, "AGI": 50},
		"moves": ["Ice Beam", "Shadow Punch", "Frost Breath", "Spirit Shackle"]
	},
	"Sativaur": {
		"types": [TYPES.GRASS, TYPES.FIRE],
		"base_stats": {"VIT": 60, "STR": 50, "RES": 55, "ESS": 75, "SPI": 65, "AGI": 65},
		"moves": ["Magical Leaf", "Flame Charge", "Solar Beam", "Fire Spin"]
	},
	"Marijuadon": {
		"types": [TYPES.GRASS, TYPES.PSYCHIC],
		"base_stats": {"VIT": 120, "STR": 70, "RES": 80, "ESS": 100, "SPI": 110, "AGI": 40},
		"moves": ["Leaf Storm", "Psychic", "Seed Bomb", "Future Sight"]
	},
	"Shocksteed": {
		"types": [TYPES.BUG, TYPES.ELECTRIC],
		"base_stats": {"VIT": 60, "STR": 60, "RES": 50, "ESS": 100, "SPI": 70, "AGI": 110},
		"moves": ["Signal Beam", "Thunderbolt", "Bug Buzz", "Volt Switch"]
	},
	"Ryno": {
		"types": [TYPES.FIGHTING],
		"base_stats": {"VIT": 100, "STR": 130, "RES": 100, "ESS": 30, "SPI": 40, "AGI": 50},
		"moves": ["Brick Break", "Rock Smash", "Close Combat", "Superpower"]
	}
}

const MOVES_DATABASE = {
	"Ember": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.SPECIAL, "power": 40, "accuracy": 100, "pp": 25},
	"Astonish": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.PHYSICAL, "power": 30, "accuracy": 100, "pp": 15},
	"Shadow Sneak": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.PHYSICAL, "power": 40, "accuracy": 100, "pp": 30},
	"Flame Burst": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.SPECIAL, "power": 70, "accuracy": 100, "pp": 15},
	"Flame Wheel": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.PHYSICAL, "power": 60, "accuracy": 100, "pp": 25},
	"Shadow Ball": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.SPECIAL, "power": 80, "accuracy": 100, "pp": 15},
	"Hex": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.SPECIAL, "power": 65, "accuracy": 100, "pp": 10},
	"Incinerate": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.SPECIAL, "power": 60, "accuracy": 100, "pp": 15},
	"Flamethrower": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.SPECIAL, "power": 90, "accuracy": 100, "pp": 15},
	"Phantom Force": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.PHYSICAL, "power": 90, "accuracy": 100, "pp": 10},
	"Inferno": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.SPECIAL, "power": 100, "accuracy": 50, "pp": 5},
	"Ominous Wind": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.SPECIAL, "power": 60, "accuracy": 100, "pp": 5},
	"Water Gun": {"type": TYPES.WATER, "category": MOVE_CATEGORY.SPECIAL, "power": 40, "accuracy": 100, "pp": 25},
	"Gust": {"type": TYPES.FLYING, "category": MOVE_CATEGORY.SPECIAL, "power": 40, "accuracy": 100, "pp": 35},
	"Bubble": {"type": TYPES.WATER, "category": MOVE_CATEGORY.SPECIAL, "power": 40, "accuracy": 100, "pp": 30},
	"Wing Attack": {"type": TYPES.FLYING, "category": MOVE_CATEGORY.PHYSICAL, "power": 60, "accuracy": 100, "pp": 35},
	"Water Pulse": {"type": TYPES.WATER, "category": MOVE_CATEGORY.SPECIAL, "power": 60, "accuracy": 100, "pp": 20},
	"Aerial Ace": {"type": TYPES.FLYING, "category": MOVE_CATEGORY.PHYSICAL, "power": 60, "accuracy": 101, "pp": 20},
	"Aqua Jet": {"type": TYPES.WATER, "category": MOVE_CATEGORY.PHYSICAL, "power": 40, "accuracy": 100, "pp": 20},
	"Air Cutter": {"type": TYPES.FLYING, "category": MOVE_CATEGORY.SPECIAL, "power": 60, "accuracy": 95, "pp": 25},
	"Hydro Pump": {"type": TYPES.WATER, "category": MOVE_CATEGORY.SPECIAL, "power": 110, "accuracy": 80, "pp": 5},
	"Hurricane": {"type": TYPES.FLYING, "category": MOVE_CATEGORY.SPECIAL, "power": 110, "accuracy": 70, "pp": 10},
	"Aqua Tail": {"type": TYPES.WATER, "category": MOVE_CATEGORY.PHYSICAL, "power": 90, "accuracy": 90, "pp": 10},
	"Sky Attack": {"type": TYPES.FLYING, "category": MOVE_CATEGORY.PHYSICAL, "power": 140, "accuracy": 90, "pp": 5},
	"Vine Whip": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.PHYSICAL, "power": 45, "accuracy": 100, "pp": 25},
	"Thunder Shock": {"type": TYPES.ELECTRIC, "category": MOVE_CATEGORY.SPECIAL, "power": 40, "accuracy": 100, "pp": 30},
	"Razor Leaf": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.PHYSICAL, "power": 55, "accuracy": 95, "pp": 25},
	"Spark": {"type": TYPES.ELECTRIC, "category": MOVE_CATEGORY.PHYSICAL, "power": 65, "accuracy": 100, "pp": 20},
	"Bulldoze": {"type": TYPES.GROUND, "category": MOVE_CATEGORY.PHYSICAL, "power": 60, "accuracy": 100, "pp": 20},
	"Thunder Fang": {"type": TYPES.ELECTRIC, "category": MOVE_CATEGORY.PHYSICAL, "power": 65, "accuracy": 95, "pp": 15},
	"Dig": {"type": TYPES.GROUND, "category": MOVE_CATEGORY.PHYSICAL, "power": 80, "accuracy": 100, "pp": 10},
	"Discharge": {"type": TYPES.ELECTRIC, "category": MOVE_CATEGORY.SPECIAL, "power": 80, "accuracy": 100, "pp": 15},
	"Giga Drain": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.SPECIAL, "power": 75, "accuracy": 100, "pp": 10},
	"Dragon Breath": {"type": TYPES.DRAGON, "category": MOVE_CATEGORY.SPECIAL, "power": 60, "accuracy": 100, "pp": 20},
	"Energy Ball": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.SPECIAL, "power": 90, "accuracy": 100, "pp": 10},
	"Dragon Pulse": {"type": TYPES.DRAGON, "category": MOVE_CATEGORY.SPECIAL, "power": 85, "accuracy": 100, "pp": 10},
	"Ice Shard": {"type": TYPES.ICE, "category": MOVE_CATEGORY.PHYSICAL, "power": 40, "accuracy": 100, "pp": 30},
	"Lick": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.PHYSICAL, "power": 30, "accuracy": 100, "pp": 30},
	"Icy Wind": {"type": TYPES.ICE, "category": MOVE_CATEGORY.SPECIAL, "power": 55, "accuracy": 95, "pp": 15},
	"Night Shade": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.SPECIAL, "power": 50, "accuracy": 100, "pp": 15},
	"Ice Beam": {"type": TYPES.ICE, "category": MOVE_CATEGORY.SPECIAL, "power": 90, "accuracy": 100, "pp": 10},
	"Shadow Punch": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.PHYSICAL, "power": 60, "accuracy": 101, "pp": 20},
	"Frost Breath": {"type": TYPES.ICE, "category": MOVE_CATEGORY.SPECIAL, "power": 60, "accuracy": 90, "pp": 10},
	"Spirit Shackle": {"type": TYPES.GHOST, "category": MOVE_CATEGORY.PHYSICAL, "power": 80, "accuracy": 100, "pp": 10},
	"Magical Leaf": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.SPECIAL, "power": 60, "accuracy": 101, "pp": 20},
	"Flame Charge": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.PHYSICAL, "power": 50, "accuracy": 100, "pp": 20},
	"Solar Beam": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.SPECIAL, "power": 120, "accuracy": 100, "pp": 10},
	"Fire Spin": {"type": TYPES.FIRE, "category": MOVE_CATEGORY.SPECIAL, "power": 35, "accuracy": 85, "pp": 15},
	"Leaf Storm": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.SPECIAL, "power": 130, "accuracy": 90, "pp": 5},
	"Psychic": {"type": TYPES.PSYCHIC, "category": MOVE_CATEGORY.SPECIAL, "power": 90, "accuracy": 100, "pp": 10},
	"Seed Bomb": {"type": TYPES.GRASS, "category": MOVE_CATEGORY.PHYSICAL, "power": 80, "accuracy": 100, "pp": 15},
	"Future Sight": {"type": TYPES.PSYCHIC, "category": MOVE_CATEGORY.SPECIAL, "power": 120, "accuracy": 100, "pp": 10},
	"Signal Beam": {"type": TYPES.BUG, "category": MOVE_CATEGORY.SPECIAL, "power": 75, "accuracy": 100, "pp": 15},
	"Thunderbolt": {"type": TYPES.ELECTRIC, "category": MOVE_CATEGORY.SPECIAL, "power": 90, "accuracy": 100, "pp": 15},
	"Bug Buzz": {"type": TYPES.BUG, "category": MOVE_CATEGORY.SPECIAL, "power": 90, "accuracy": 100, "pp": 10},
	"Volt Switch": {"type": TYPES.ELECTRIC, "category": MOVE_CATEGORY.SPECIAL, "power": 70, "accuracy": 100, "pp": 20},
	"Brick Break": {"type": TYPES.FIGHTING, "category": MOVE_CATEGORY.PHYSICAL, "power": 75, "accuracy": 100, "pp": 15},
	"Rock Smash": {"type": TYPES.FIGHTING, "category": MOVE_CATEGORY.PHYSICAL, "power": 40, "accuracy": 100, "pp": 15},
	"Close Combat": {"type": TYPES.FIGHTING, "category": MOVE_CATEGORY.PHYSICAL, "power": 120, "accuracy": 100, "pp": 5},
	"Superpower": {"type": TYPES.FIGHTING, "category": MOVE_CATEGORY.PHYSICAL, "power": 120, "accuracy": 100, "pp": 5},
}

const TYPE_EFFECTIVENESS_CHART = {
	TYPES.NORMAL: {
		TYPES.ROCK: 0.5,
		TYPES.GHOST: 0.0,
		TYPES.STEEL: 0.5
	},
	TYPES.FIRE: {
		TYPES.FIRE: 0.5,
		TYPES.WATER: 0.5,
		TYPES.GRASS: 2.0,
		TYPES.ICE: 2.0,
		TYPES.BUG: 2.0,
		TYPES.ROCK: 0.5,
		TYPES.DRAGON: 0.5,
		TYPES.STEEL: 2.0
	},
	TYPES.WATER: {
		TYPES.FIRE: 2.0,
		TYPES.WATER: 0.5,
		TYPES.GRASS: 0.5,
		TYPES.GROUND: 2.0,
		TYPES.ROCK: 2.0,
		TYPES.DRAGON: 0.5
	},
	TYPES.GRASS: {
		TYPES.FIRE: 0.5,
		TYPES.WATER: 2.0,
		TYPES.GRASS: 0.5,
		TYPES.POISON: 0.5,
		TYPES.GROUND: 2.0,
		TYPES.FLYING: 0.5,
		TYPES.BUG: 0.5,
		TYPES.ROCK: 2.0,
		TYPES.DRAGON: 0.5,
		TYPES.STEEL: 0.5
	},
	TYPES.ELECTRIC: {
		TYPES.WATER: 2.0,
		TYPES.ELECTRIC: 0.5,
		TYPES.GRASS: 0.5,
		TYPES.GROUND: 0.0,
		TYPES.FLYING: 2.0,
		TYPES.DRAGON: 0.5
	},
	TYPES.ICE: {
		TYPES.FIRE: 0.5,
		TYPES.WATER: 0.5,
		TYPES.GRASS: 2.0,
		TYPES.ICE: 0.5,
		TYPES.GROUND: 2.0,
		TYPES.FLYING: 2.0,
		TYPES.DRAGON: 2.0,
		TYPES.STEEL: 0.5
	},
	TYPES.FIGHTING: {
		TYPES.NORMAL: 2.0,
		TYPES.ICE: 2.0,
		TYPES.POISON: 0.5,
		TYPES.FLYING: 0.5,
		TYPES.PSYCHIC: 0.5,
		TYPES.BUG: 0.5,
		TYPES.ROCK: 2.0,
		TYPES.GHOST: 0.0,
		TYPES.DARK: 2.0,
		TYPES.STEEL: 2.0,
		TYPES.FAIRY: 0.5
	},
	TYPES.POISON: {
		TYPES.GRASS: 2.0,
		TYPES.POISON: 0.5,
		TYPES.GROUND: 0.5,
		TYPES.ROCK: 0.5,
		TYPES.GHOST: 0.5,
		TYPES.STEEL: 0.0,
		TYPES.FAIRY: 2.0
	},
	TYPES.GROUND: {
		TYPES.FIRE: 2.0,
		TYPES.ELECTRIC: 2.0,
		TYPES.GRASS: 0.5,
		TYPES.POISON: 2.0,
		TYPES.FLYING: 0.0,
		TYPES.BUG: 0.5,
		TYPES.ROCK: 2.0,
		TYPES.STEEL: 2.0
	},
	TYPES.FLYING: {
		TYPES.ELECTRIC: 0.5,
		TYPES.GRASS: 2.0,
		TYPES.FIGHTING: 2.0,
		TYPES.BUG: 2.0,
		TYPES.ROCK: 0.5,
		TYPES.STEEL: 0.5
	},
	TYPES.PSYCHIC: {
		TYPES.FIGHTING: 2.0,
		TYPES.POISON: 2.0,
		TYPES.PSYCHIC: 0.5,
		TYPES.DARK: 0.0,
		TYPES.STEEL: 0.5
	},
	TYPES.BUG: {
		TYPES.FIRE: 0.5,
		TYPES.GRASS: 2.0,
		TYPES.FIGHTING: 0.5,
		TYPES.POISON: 0.5,
		TYPES.FLYING: 0.5,
		TYPES.PSYCHIC: 2.0,
		TYPES.GHOST: 0.5,
		TYPES.DARK: 2.0,
		TYPES.STEEL: 0.5,
		TYPES.FAIRY: 0.5
	},
	TYPES.ROCK: {
		TYPES.FIRE: 2.0,
		TYPES.ICE: 2.0,
		TYPES.FIGHTING: 0.5,
		TYPES.GROUND: 0.5,
		TYPES.FLYING: 2.0,
		TYPES.BUG: 2.0,
		TYPES.STEEL: 0.5
	},
	TYPES.GHOST: {
		TYPES.NORMAL: 0.0,
		TYPES.PSYCHIC: 2.0,
		TYPES.GHOST: 2.0,
		TYPES.DARK: 0.5
	},
	TYPES.DRAGON: {
		TYPES.DRAGON: 2.0,
		TYPES.STEEL: 0.5,
		TYPES.FAIRY: 0.0
	},
	TYPES.DARK: {
		TYPES.FIGHTING: 0.5,
		TYPES.PSYCHIC: 2.0,
		TYPES.GHOST: 2.0,
		TYPES.DARK: 0.5,
		TYPES.FAIRY: 0.5
	},
	TYPES.STEEL: {
		TYPES.FIRE: 0.5,
		TYPES.WATER: 0.5,
		TYPES.ELECTRIC: 0.5,
		TYPES.ICE: 2.0,
		TYPES.ROCK: 2.0,
		TYPES.STEEL: 0.5,
		TYPES.FAIRY: 2.0
	},
	TYPES.FAIRY: {
		TYPES.FIRE: 0.5,
		TYPES.FIGHTING: 2.0,
		TYPES.POISON: 0.5,
		TYPES.DRAGON: 2.0,
		TYPES.DARK: 2.0,
		TYPES.STEEL: 0.5
	}
}

const OPPONENTS = {
	# "TrainerName": {"team": ["Unamon1", "Unamon2", ...]},
	"Ego":      {"team": ["Wyvorophyll", "Marijuadon", "Ignantom", "Marinawk", "Shocksteed", "Ryno"]},
	# Final Team: ["Mamantera", "Tephron", "Chrysogor", "Primoricorn", "Apoploox", "Voidborne"]
	"Brooks":   {"team": ["Ryno", "Cracklesap", "Flopix"]},
	# Final Team: ["Sutursa", "Ryno", "Oryzoki", "Cracklesap", "Aquilia"]
	"Penny":    {"team": ["Ignantom", "Cryophant", "Shocksteed", "Salamendro", "Smoglet"]},
	# Final Team: ["Mutamania", "Myrkkane", "Apoploox", "Ignantom", "Landignor", "Vocifer"]
	"Aimee":    {"team": ["Cryoul", "Flopix", "Aquilia", "Smoglet", "Cracklesap"]},
	# Final Team: ["Cryoul", "Cryophant", "Orgamarina", "Spookspew", "Exvil"]
	"Amy":      {"team": ["Marinawk", "Flopix", "Aquilia", "Sativaur", "Marijuadon", "Wyvorophyll"]},
	# Final Team: ["Aquamyst", "Marinawk", "Sativaur", "Primoricorn", "Chrysogor", "Sutursa"]
	"Ayla":     {"team": ["Shocksteed", "Salamendro", "Ignantom", "Ryno", "Wyvorophyll"]},
	# Final Team: ["Faerumen", "Shocksteed", "Stainana", "Plumaru", "Magmoroch", "Excavolt"]
	"Bas":      {"team": ["Ryno", "Cracklesap", "Salamendro", "Smoglet", "Cryoul", "Flopix"]},
	# Final Team: ["Oryzoki", "Ryno", "Titanger", "Salamendro", "Grumbo", "Terravore"]
	"Dustin":   {"team": ["Salamendro", "Cracklesap", "Shocksteed", "Sativaur", "Flopix", "Smoglet"]},
	# Final Team: ["Galactortle", "Marijuadon", "Shocksteed", "Sativaur", "Wyfern", "Smoglet"]
	"Esther":   {"team": ["Flopix", "Aquilia", "Sativaur", "Cracklesap", "Shocksteed"]},
	# Final Team: ["Tephron", "Chrysogor", "Aquilia", "Gryfleia", "Primoricorn", "Shocksteed"]
	"Ghost":    {"team": ["Smoglet", "Flamura", "Ignantom", "Cryoul", "Cryophant", "Wyvorophyll"]},
	# Final Team: ["Mamantera", "Vocifer", "Voidborne", "Ignantom", "Cryolantis", "Apoploox"]
	"KOL":      {"team": ["Ignantom", "Salamendro", "Ryno", "Shocksteed", "Marinawk", "Wyvorophyll"]},
	# Final Team: ["Ignantom", "Stainana", "Dhascarab", "Afterwrithe", "Magmoroch", "Ryno"]
	"Melanie":  {"team": ["Ignantom", "Wyvorophyll", "Marinawk", "Ryno", "Shocksteed", "Cryophant"]},
	# Final Team: ["Faerumen", "Stainana", "Gryfnosa", "Ferrizari", "Sekhant", "Myrkkane"]
	"Miyamoto": {"team": ["Wyvorophyll", "Marijuadon", "Ryno", "Shocksteed", "Ignantom", "Marinawk"]},
	# Final Team: ["Wyvorophyll", "Marijuadon", "Ryno", "Tephron", "Chrysogor", "Terravore"]
	"OJ":       {"team": ["Smoglet", "Flamura", "Cryoul", "Flopix"]},
	# Final Team: ["Spookspew", "Ectoxomoth", "Inkitsu", "Flamf", "Cryoul"]
	"Pato":     {"team": ["Marinawk", "Aquilia", "Flopix", "Ryno", "Salamendro", "Shocksteed"]},
	# Final Team: ["Marinawk", "Dhascarab", "Gryfleia", "Sekhant", "Stainana", "Ferrizari"]
	"Satoshi":  {"team": ["Wyvorophyll", "Marijuadon", "Ignantom", "Shocksteed", "Ryno", "Cryophant"]},
	# Final Team: ["Primoricorn", "Cryolantis", "Folyvern", "Stainana", "Faerumen", "Apoploox"]
	"Sonia":    {"team": ["Sativaur", "Flopix", "Aquilia", "Cracklesap", "Smoglet"]},
	# Final Team: ["Sativaur", "Flamf", "Ampixie", "Flopix", "Pineapuss", "Wottle"]
	"Trix":     {"team": ["Shocksteed", "Ignantom", "Salamendro", "Marinawk", "Ryno", "Wyvorophyll"]},
	# Final Team: ["Chrysogor", "Wyvorophyll", "Sutursa", "Tephron", "Galactortle", "Shocksteed"]
	"Bkyu":     {"team": ["Shocksteed", "Sativaur", "Flopix", "Marijuadon", "Cracklesap", "Aquilia"]},
	# Final Team: ["Shocksteed", "Faerumen", "Marijuadon", "Flamf", "Vesophry", "Ampixie"]
	"Id":       {"team": ["Ignantom", "Cryophant", "Wyvorophyll", "Ryno", "Marinawk", "Shocksteed"]},
	# Final Team: ["Voidborne", "Afterwrithe", "Myrkkane", "Apoploox", "Vesophry", "Inkitsu"]
	"Xerberus": {"team": ["Ignantom", "Ryno", "Marinawk", "Shocksteed", "Wyvorophyll", "Cryophant"]},
	# Final Team: ["Magmoroch", "Cryolantis", "Afterwrithe", "Tephron", "Stainana", "Vesophry"]
	"Asteria":  {"team": ["Marijuadon", "Wyvorophyll", "Sativaur", "Flopix", "Aquilia", "Cracklesap"]},
	# Final Team: ["Mamantera", "Galactortle", "Chrysogor", "Tephron", "Primoricorn", "Absequi"]
	"Kixxie": {"team": ["Shocksteed", "Marinawk", "Ignantom", "Sativaur"]},
	# Final Team: ["Faerumen", "Excavolt", "Vesophry", "Tephron (Ash Forme)", "Plumaru", "Inkitsu"]}
	
	# THIRD PARTY CHARACTERS
	"CoolStick": {"team": ["Ryno", "Ignantom", "Cryoul"]},
	"BlackShadow": {"team": ["Ignantom", "Shocksteed"]},
	"SunMan": {"team": ["Salamendro", "Aquilia"]},
	"MoonManiac": {"team": ["Cryoul", "Marinawk"]},
	
	# PJ AU'S
	"Ohayo":      {"team": ["Shocksteed", "Cracklesap", "Smoglet", "Flopix"]},
	# Final Team: ["Faerumen", "Excavolt", "Vesophry", "Tephron", "Stad", "Plumaru"]
	"PJR":       {"team": ["Ryno", "Marinawk", "Ignantom", "Wyvorophyll", "Shocksteed"]},
	# Final Team: ["Galactortle", "Voidborne", "Mamantera", "Cryolantis", "Stainana", "Tephron"]
	"PostJay":   {"team": ["Flamura", "Cryoul", "Flopix", "Sativaur"]},
	# Final Team: ["Inkitsu", "Vocifer", "Neurocowl", "Sutursa", "Absequi", "Chrysogor"]
	"SuperNova": {"team": ["Ryno", "Ignantom", "Shocksteed", "Marinawk"]},
	# Final Team: ["Mamantera", "Tephron", "Faerumen", "Magmoroch", "Primoricorn", "Voidborne"]
	
	# OTHER DIMENSIONS
	"DeDe": {"team": ["Ryno", "Ignantom", "Shocksteed"]},
	"Smiley": {"team": ["Ignantom", "Cryoul", "Flamura", "Wyvorophyll"]},
	"Laura": {"team": ["Cracklesap, Smoglet, Flopix"]},
	# Final Team: Wyvorophyll, Ignantom, Marinawk, Sutursa, Absequi, Chrysogor
	"Lila": {"team": ["Flopix, Sativaur"]},
	# Final Team: Vesophry, Apoploox, Myrkkane, Neurocowl, Voidborne, Spookspew
	"Tobias": {"team": ["Cracklesap, Flopix"]},
	# Final Team: Stainana, Magmoroch, Excavolt, Faerumen, Plumaru, Shocksteed
	"Sergeant": {"team": ["Ignantom, Salamendro"]},
	# Final Team: Ryno, Stainana, Ignantom, Magmoroch, Titanger, Ferrizari
	"Wächter": {"team": ["Ryno, Salamendro", "Ignantom"]},
	# Final Team: Ryno, Titanger, Stainana, Ignantom, Magmoroch, Excavolt
	"Sans": {"team": ["Smoglet", "Cryoul"]},
	# Final Team: Apoploox, Gryfnosa, Voidborne, Cryolantis, Ignantom, Myrkkane
	"Marceline": {"team": ["Ignantom", "Cryoul", "Smoglet"]},
	# Final Team: Apoploox, Myrkkane, Vesophry, Vocifer, Spookspew, Neurocowl
	"Sonic.exe": {"team": ["Ignantom"]},
	# Final Team: Voidborne, Apoploox, Myrkkane, Afterwrithe, Ignantom, Vesophry
	"Walter": {"team": ["Sativaur", "Smoglet", "Cracklesap"]},
	# Final Team: Myrkkane, Spookspew, Mosantis, Exvil, Ectoxomoth, Vesophry
	"The Rock": {"team": ["Ryno", "Ignantom", "Salamendro"]},
	# Final Team: Titanger, Ryno, Landignor, Stainana, Gryfleia, Terroforma
	"Agent Mason": {"team": ["Marinawk", "Salamendro", "Shocksteed"]},
	# Final Team: Ferrizari, Stainana, Excavolt, Gryfleia, Tephron, Aquamyst
	"General Tut": {"team": ["Ryno", "Ignantom", "Salamendro", "Shocksteed"]},
	# Final Team: Titanger, Stainana, Magmoroch, Apoploox, Ferrizari, Excavolt
	"Daisy": {"team": ["Flamf", "Nutlet", "Wottle"]},
	# Final Team: Mutamania, Mosantis, Spookspew, Exvil, Vesophry, Apoploox
	"O5-1": {"team": ["Aquilia", "Cracklesap", "Sativaur"]},
	# Final Team: Tephron, Chrysogor, Galactortle, Sutursa, Primoricorn, Faerumen
	"O5-2": {"team": ["Ryno", "Salamendro", "Corvapse"]},
	# Final Team: Titanger, Stainana, Magmoroch, Afterwrithe, Terroforma, Excavolt
	# "05-4": {"team": ["Gryfnosa", "Apoploox", "Myrkkane", "Vesophry", "Voidborne", "Inkitsu"]},
	
	
}


static func calculate_unamon_stats(base_unamon_data: Dictionary, level: int = 50):
	var calculated_stats = {}
	var base_stats = base_unamon_data.base_stats
	
	# HP = ((2 * Base + IV + EV/4) * Level / 100) + Level + 10
	calculated_stats.max_hp = int(((2 * base_stats.VIT + 31 + 0) * level / 100.0) + level + 10)
	calculated_stats.current_hp = calculated_stats.max_hp
	
	# Other stats = ((2 * Base + IV + EV/4) * Level / 100) + 5
	calculated_stats.attack = int(((2 * base_stats.STR + 31 + 0) * level / 100.0) + 5)
	calculated_stats.defense = int(((2 * base_stats.RES + 31 + 0) * level / 100.0) + 5)
	calculated_stats.special_attack = int(((2 * base_stats.ESS + 31 + 0) * level / 100.0) + 5)
	calculated_stats.special_defense = int(((2 * base_stats.SPI + 31 + 0) * level / 100.0) + 5)
	calculated_stats.speed = int(((2 * base_stats.AGI + 31 + 0) * level / 100.0) + 5)
	
	return calculated_stats

static func create_unamon_instance(unamon_name: String, min_level: int = 45, max_level: int = 55):
	if not UNAMON_DATABASE.has(unamon_name):
		printerr("Unamon not found in database: ", unamon_name)
		return null

	var base_data = UNAMON_DATABASE[unamon_name]
	var instance = base_data.duplicate(true)
	instance.name = unamon_name
	instance.level = randi_range(min_level, max_level)
	instance.calculated_stats = calculate_unamon_stats(base_data, instance.level)

	var moves_instances = []
	for move_name_str in base_data.moves:
		if MOVES_DATABASE.has(move_name_str):
			var move_data = MOVES_DATABASE[move_name_str].duplicate(true)
			move_data.name = move_name_str
			move_data.current_pp = move_data.pp 
			moves_instances.append(move_data)
		else:
			printerr("Move not found in database: ", move_name_str, " for Unamon: ", unamon_name)
	instance.battle_moves = moves_instances

	return instance

static func get_type_effectiveness(move_type: TYPES, defender_types: Array) -> float:
	var overall_multiplier = 1.0
	if TYPE_EFFECTIVENESS_CHART.has(move_type) and TYPE_EFFECTIVENESS_CHART[move_type] != null:
		var attack_effectiveness = TYPE_EFFECTIVENESS_CHART[move_type]
		for def_type in defender_types:
			if attack_effectiveness.has(def_type):
				overall_multiplier *= attack_effectiveness[def_type]
	return overall_multiplier

static func get_all_unamon_names() -> Array:
	return UNAMON_DATABASE.keys()

static func get_opponent_names() -> Array:
	return OPPONENTS.keys()

static func get_opponent_data(opponent_name: String) -> Dictionary:
		if OPPONENTS.has(opponent_name):
			return OPPONENTS[opponent_name]
		printerr("Opponent data not found for: ", opponent_name) # Add error message
		return {} # Return empty dictionary if not found

static func get_type_name(type_enum: TYPES) -> String:
	if type_enum >= 0 and type_enum < TYPES.size(): # Basic bounds check
		return TYPES.keys()[type_enum]
	return "UNKNOWN_TYPE"


static func get_move_category_name(cat_enum: MOVE_CATEGORY) -> String:
	if cat_enum >=0 and cat_enum < MOVE_CATEGORY.size(): # Basic bounds check
		return MOVE_CATEGORY.keys()[cat_enum]
	return "UNKNOWN_CAT"
