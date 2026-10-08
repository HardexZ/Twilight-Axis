/// Cooldown between two ear swaps made with the RoleUnique button.
#define RABBIT_EAR_SWAP_COOLDOWN (3 SECONDS)

/// Rabbit ear styles that can be cycled through with the button, in cycle order:
/// Medium -> Floppy -> Floppy R. -> Medium -> ...
GLOBAL_LIST_INIT(rabbit_ear_swap_cycle, list(
	/datum/sprite_accessory/ears/big/rabbit_medium,
	/datum/sprite_accessory/ears/big/rabbit_floppy,
	/datum/sprite_accessory/ears/big/rabbit_floppyalt,
))

/mob/living/carbon/human
	COOLDOWN_DECLARE(rabbit_ear_swap_cd)

/// TRUE if this human currently wears one of the swappable rabbit ear styles.
/mob/living/carbon/human/proc/has_swappable_rabbit_ears()
	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	if(!ears || !ears.accessory_type)
		return FALSE
	return (ears.accessory_type in GLOB.rabbit_ear_swap_cycle)

/// Grants the RoleUnique button if the ears are swappable rabbit ears, otherwise takes it away.
/// Called from the ears organ on Insert/Remove, so it also covers the mirror / customisation paths.
/mob/living/carbon/human/proc/update_rabbit_ear_swap_verb()
	if(has_swappable_rabbit_ears())
		add_verb(src, /mob/living/carbon/human/proc/swap_rabbit_ears)
	else
		remove_verb(src, /mob/living/carbon/human/proc/swap_rabbit_ears)

/mob/living/carbon/human/proc/swap_rabbit_ears()
	set name = "Swap Rabbit Ears"
	set category = "RoleUnique.Ears"
	set desc = "Change the shape of my rabbit ears."

	if(stat == DEAD)
		return

	// Safety net: ears could have been changed in a way that did not trigger Insert/Remove.
	if(!has_swappable_rabbit_ears())
		remove_verb(src, /mob/living/carbon/human/proc/swap_rabbit_ears)
		to_chat(src, span_warning("I don't have rabbit ears that I could move around."))
		return

	if(!COOLDOWN_FINISHED(src, rabbit_ear_swap_cd))
		var/seconds_left = CEILING((rabbit_ear_swap_cd - world.time) / 10, 1)
		to_chat(src, span_warning("My ears need a moment before I can fidget with them again ([seconds_left]s)."))
		return

	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	var/list/cycle = GLOB.rabbit_ear_swap_cycle
	var/current_index = cycle.Find(ears.accessory_type)
	var/new_type = cycle[(current_index % length(cycle)) + 1]

	// Passing the current colours keeps the player's colours: all three styles use the same 3 colour keys.
	ears.set_accessory_type(new_type, ears.accessory_colors)

	// Keep the stored organ DNA in sync, so the new style survives organ regeneration / species updates.
	if(dna)
		var/datum/organ_dna/ear_dna = dna.organ_dna[ORGAN_SLOT_EARS]
		if(ear_dna)
			ear_dna.accessory_type = new_type
			ear_dna.accessory_colors = ears.accessory_colors

	update_body()
	COOLDOWN_START(src, rabbit_ear_swap_cd, RABBIT_EAR_SWAP_COOLDOWN)

	var/datum/sprite_accessory/new_style = SPRITE_ACCESSORY(new_type)
	to_chat(src, span_notice("I shift my ears into [new_style.name]."))
