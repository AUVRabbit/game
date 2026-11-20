#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 AI 素材清单 tools/asset_manifest.json

用法：python3 tools/gen_manifest.py
输出：每条 {id, path, prompt, out_size}
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ICON_STYLE = (
    "digital game UI icon, hand-painted dark-fantasy steampunk-punk art style, "
    "bold readable silhouette, strong rim light, high contrast, centered single subject, "
    "square composition, solid deep charcoal #14161c background with subtle vignette, "
    "no text, no letters, no logo, no watermark"
)

PORTRAIT_STYLE = (
    "character portrait bust, three-quarter view, hand-painted dark-fantasy steampunk-punk art style, "
    "dramatic rim lighting, detailed face and gear, centered, square composition, "
    "solid deep charcoal #14161c background with subtle vignette, no text, no letters, no watermark"
)

VFX_STYLE = (
    "game VFX sprite, luminous glowing energy effect, pure black background, "
    "high intensity emissive colors suitable for additive blending, soft edges, "
    "centered composition, no text, no watermark"
)

ENEMY_STYLE = (
    "top-down video game enemy sprite, hand-painted dark-fantasy steampunk-punk art style, "
    "readable silhouette, centered, square composition, solid deep charcoal #14161c background, "
    "no text, no watermark"
)

SKILL_SUBJECT = {
    "whirlwind": "a spinning broad sword slash arc carving a circular whirlwind of steel",
    "war_cry": "a roaring warrior helmet emitting a golden shockwave of battle cry",
    "shield_wall": "a heavy steel tower shield bristling with rivets and a blocking stance",
    "piercing_shot": "a long piercing arrow wrapped in piercing green wind energy",
    "arrow_rain": "a downpour of glowing arrows raining from the sky",
    "hawk_eye": "a keen eagle eye with golden targeting reticle rings",
    "fireball": "a blazing orange fireball meteor with trailing flame",
    "frost_nova": "a ring of jagged blue ice shards exploding outward",
    "arcane_shield": "a hexagonal violet arcane barrier dome with runes",
    "heal": "a radiant green healing cross of light and rising motes",
    "holy_nova": "a burst of golden holy light rays forming a nova",
    "blessing": "a golden blessing halo with descending light feathers",
    "corrupt_bolt": "a sickly green necrotic energy bolt dripping rot",
    "grave_field": "a cursed graveyard circle of raised tombstone glyphs",
    "drain": "a violet life-drain siphon pulling a soul thread into a skull",
    "death_charge": "a crimson knight charging forward with a dark speed trail",
    "blood_slash": "a diagonal blood-red sword slash dripping crimson",
    "dark_shield": "a black obsidian dome shield with purple runes",
    "backstab": "a stealth dagger strike from behind in teal shadow",
    "smoke_bomb": "a round smoke bomb canister venting grey smoke",
    "poison_blade": "a slim poison-coated dagger dripping green toxin",
    "snipe": "a long sniper rifle barrel with a golden precision scope",
    "trap": "a mechanical ground trap with steel jaws and green gas",
    "focus": "a focused crosshair eye with golden concentration beams",
    "throw_bomb": "a thrown iron bomb with a burning fuse",
    "blast_zone": "an orange blast crater ring with rising fire",
    "incendiary": "a burning incendiary splash with spreading flames",
    "virus": "a green computer virus code blob corrupting a circuit",
    "emp_pulse": "a cyan electromagnetic pulse ring with lightning arcs",
    "overclock": "an overclocked CPU core glowing with heat and cyan energy",
    "cannon": "a heavy siege cannon muzzle firing a golden shell",
    "armor_up": "a mech pilot chest plate locking into armored mode",
    "energy_field": "a hexagonal energy field dome around a mech core",
    "rapid_fire": "a rapid-fire gatling gun barrel with muzzle flashes",
    "mark": "a pink tracking marker reticle stamped on a target",
    "disarm": "a bounty hunter disarm wrench snapping a weapon",
}

ITEM_SUBJECT = {
    "grass": "a square tile of lush green grass turf",
    "stone": "a rough grey cobblestone chunk",
    "wood": "a bundle of cut wooden logs",
    "iron_ore": "a chunk of raw iron ore rock with metallic veins",
    "iron_ingot": "a polished iron ingot bar",
    "herb": "a bundle of healing green herbs",
    "leather": "a folded tanned leather hide",
    "slime_gel": "a blob of glowing green slime gel",
    "mech_core": "a cogs and pipes mechanical core with a glowing cyan lens",
    "ghost_dust": "a swirling cloud of pale ghostly spectral dust",
    "healing_potion": "a red liquid healing potion in a glass bottle",
    "mana_potion": "a blue liquid mana potion in a glass bottle",
    "stone_block": "a neatly cut stone brick block",
    "wood_block": "a neatly cut wooden plank block",
    "wall": "a solid stone wall segment",
    "fence": "a wooden fence segment",
    "torch": "a burning wall torch with warm flame",
    "bed": "a simple wooden bed with straw mattress",
    "chest": "a iron-banded treasure chest",
    "weapon_sword_iron": "a plain iron longsword with leather grip",
    "weapon_bow_wood": "a wooden recurve bow with a strung arrow",
    "staff_apprentice": "an apprentice mage staff with a glowing blue crystal",
    "armor_leather": "a brown leather chest armor vest with buckles",
    "amulet_swift": "a silver amulet with a wind swirl gemstone",
    "key_tower": "an ornate golden tower key",
}

CLASS_SUBJECT = {
    "warrior": "a grizzled swordsman with heavy riveted plate armor and a glowing red blade",
    "archer": "a nimble hooded ranger holding a wind-charged longbow",
    "mage": "a robed pyromancer wreathed in arcane fire with a crystal staff",
    "priest": "a radiant priestess in white-gold vestments with holy light around her hands",
    "necromancer": "a skeletal sorcerer in tattered violet robes casting a green soul bolt",
    "death_knight": "a black armored death knight with a crimson greatsword and horned helm",
    "thief": "a masked rogue in dark leather with teal daggers and smoke at his feet",
    "sniper": "a long-range marksman with a scoped rifle and golden targeting lens",
    "bomber": "a reckless bomber with a bandolier of bombs and an orange flare",
    "hacker": "a neon cyber-hacker with glowing cyan circuit tattoos and visor",
    "mech_pilot": "a mech pilot in bulky orange riveted armor with a glowing cockpit visor",
    "bounty_hunter": "a scarred bounty hunter with a gatling gun and pink neon tracker",
}

VFX_KIND = {
    "melee_slash": "a crescent sword slash arc of white-orange energy",
    "fireball": "a burning fireball comet with flame tail",
    "arrow": "a streaking arrow with wind trail",
    "explosion": "a round fireball explosion with flying debris",
    "lightning": "forked blue lightning bolts",
    "ice_shard": "jagged blue ice shards bursting outward",
    "heal_spark": "rising green healing sparkles and a soft cross of light",
    "shield_bubble": "a translucent hex-grid shield dome",
    "buff_swirl": "a golden swirl of rising light motes",
    "dash_streak": "a horizontal crimson speed streak with impact dust",
    "void_pulse": "a violet void shockwave ripple",
    "steam_burst": "a burst of white steam jets",
    "rune_glyph": "a rotating arcane rune circle of violet glyphs",
    "neon_grid": "a cyan neon circuit grid pulse",
}

PASSIVE_SUBJECT = {
    "stat_attack": "a crossed pair of battle axes emitting red energy",
    "stat_defense": "a heavy tower shield emblem with steel plating",
    "stat_crit": "a critical hit burst marker with a white impact star",
    "stat_speed": "a winged boot with wind swirls for cooldown reduction",
    "stat_skill": "an open spell tome with radiant energy pages",
    "stat_capstone": "a radiant golden trophy-like crest of mastery",
}

ENEMY_SUBJECT = {
    "slime": "a translucent green blob slime creature with a glossy highlight",
    "mech_spider": "a mechanical spider enemy with steel legs and a red glowing eye",
    "wraith": "a floating spectral wraith ghost with tattered blue robes",
    "boss": "a huge armored boss creature with glowing crimson core and heavy plating",
}

SPRITE_STYLE = (
    "top-down video game world sprite, hand-painted dark-fantasy steampunk-punk art style, "
    "single object seen from directly above at a slight isometric tilt, "
    "strong readable silhouette, evenly lit, centered composition, "
    "isolated on a plain pure chroma key magenta background #FF00FF, "
    "no ground shadow, no text, no letters, no logo, no watermark"
)

WORLD_SUBJECT = {
    # 资源点
    "res_wood": "a felled oak log pile with an axe embedded in it",
    "res_stone": "a heap of rough grey quarry boulders with chipped rock fragments",
    "res_herb": "a cluster of glowing green healing herbs sprouting from the ground",
    "res_iron_ore": "a chunk of raw iron ore rock with bright metallic veins",
    "res_leather": "a folded tanned leather hide stretched on a wooden rack",
    # NPC
    "npc_blacksmith": "a burly blacksmith NPC with a hammer, standing behind a wooden workbench",
    "npc_scholar": "a robed scholar NPC holding an open arcane tome and a brass magnifier",
    "npc_merchant": "a travelling merchant NPC with a heavy pack and a spread of goods",
    # 场景设施
    "altar": "a circular stone class-selection altar carved with glowing runes",
    "forge": "a punk workbench forge with anvil, tools and a steaming coolant tank",
    "portal": "a tall stone obelisk portal arch with a swirling violet energy vortex",
    "tower": "a towering stone tower entrance gate with iron bands and green crystal lamps",
    # 建造方块
    "block_stone_block": "a neatly cut grey stone brick block, top-down square",
    "block_wood_block": "a neatly cut wooden plank block, top-down square",
    "block_wall": "a solid stone wall segment with mortar lines, top-down square",
    "block_fence": "a wooden fence segment with two posts and rails, top-down square",
    "block_torch": "a wall torch bracket with a burning flame, top-down square",
    "block_bed": "a simple wooden bed with a straw mattress, top-down square",
    "block_chest": "an iron-banded treasure chest with a brass lock, top-down square",
    "block_grass": "a square tile of lush green grass turf, top-down square",
    # 玩家职业（俯视）
    "player_warrior": "a top-down view of a grizzled swordsman in heavy riveted plate armor",
    "player_archer": "a top-down view of a hooded ranger archer in green leather with a quiver",
    "player_mage": "a top-down view of a robed pyromancer holding a glowing crystal staff",
    "player_priest": "a top-down view of a radiant priestess in white-gold vestments",
    "player_necromancer": "a top-down view of a skeletal sorcerer in tattered violet robes",
    "player_death_knight": "a top-down view of a black armored death knight with a crimson greatsword",
    "player_thief": "a top-down view of a masked rogue in dark leather with twin daggers",
    "player_sniper": "a top-down view of a long-range marksman with a scoped rifle",
    "player_bomber": "a top-down view of a bomber with a bandolier of bombs",
    "player_hacker": "a top-down view of a neon cyber-hacker with glowing cyan circuit tattoos",
    "player_mech_pilot": "a top-down view of a mech pilot in bulky orange riveted armor",
    "player_bounty_hunter": "a top-down view of a bounty hunter with a gatling gun and pink neon tracker",
}


def build():
    entries = []
    classes = json.load(open(os.path.join(ROOT, "data/classes.json"), encoding="utf-8"))["classes"]
    for cid, cv in classes.items():
        for s in cv["skills"]:
            subject = SKILL_SUBJECT.get(s["id"], "a glowing combat skill emblem")
            entries.append({
                "id": "skill_%s" % s["id"],
                "path": "assets/icons/skill/%s" % s["id"],
                "out_size": 256,
                "prompt": "%s, subject: %s" % (ICON_STYLE, subject),
            })
    items = json.load(open(os.path.join(ROOT, "data/items.json"), encoding="utf-8"))
    items = items["items"] if isinstance(items, dict) and "items" in items else items
    if isinstance(items, dict):
        item_list = [{"id": k, **v} for k, v in items.items()]
    else:
        item_list = items
    for it in item_list:
        subject = ITEM_SUBJECT.get(it["id"], "a fantasy game item")
        entries.append({
            "id": "item_%s" % it["id"],
            "path": "assets/icons/item/%s" % it["id"],
            "out_size": 256,
            "prompt": "%s, subject: %s" % (ICON_STYLE, subject),
        })
    for cid, subject in CLASS_SUBJECT.items():
        entries.append({
            "id": "portrait_%s" % cid,
            "path": "assets/portraits/%s" % cid,
            "out_size": 512,
            "prompt": "%s, subject: %s" % (PORTRAIT_STYLE, subject),
        })
    for kind, subject in VFX_KIND.items():
        entries.append({
            "id": "vfx_%s" % kind,
            "path": "assets/vfx/%s" % kind,
            "out_size": 512,
            "prompt": "%s, subject: %s" % (VFX_STYLE, subject),
        })
    for pid, subject in PASSIVE_SUBJECT.items():
        entries.append({
            "id": "passive_%s" % pid,
            "path": "assets/icons/passive/%s" % pid,
            "out_size": 256,
            "prompt": "%s, subject: %s" % (ICON_STYLE, subject),
        })
    for eid, subject in ENEMY_SUBJECT.items():
        entries.append({
            "id": "enemy_%s" % eid,
            "path": "assets/sprites/enemy_%s" % eid,
            "out_size": 512,
            "prompt": "%s, subject: %s" % (ENEMY_STYLE, subject),
        })
    for sid, subject in WORLD_SUBJECT.items():
        entries.append({
            "id": "sprite_%s" % sid,
            "path": "assets/sprites/world/%s" % sid,
            "out_size": 512,
            "prompt": "%s, subject: %s" % (SPRITE_STYLE, subject),
        })
    out = os.path.join(ROOT, "tools/asset_manifest.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"style_note": "square opaque art; vfx on pure black for additive blending; world sprites on chroma key magenta", "entries": entries}, f, ensure_ascii=False, indent=1)
    print("entries=%d -> %s" % (len(entries), out))


if __name__ == "__main__":
    build()
