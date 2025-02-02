/obj/structure/bed/roller/ironingboard
	name = "ironing board"
	desc = "An ironing board to unwrinkle your wrinkled clothing."
	icon = 'icons/obj/ironing.dmi'
	item_form_type = /obj/item/roller/ironingboard
	iv_stand = FALSE

	var/obj/item/clothing/cloth // the clothing on the ironing board
	var/obj/item/ironingiron/holding // ironing iron on the board

/obj/structure/bed/roller/ironingboard/Initialize()
	. = ..()
	set_extension(src, /datum/extension/play_sound_on_moved)

/obj/structure/bed/roller/ironingboard/Destroy()
	var/turf/T = get_turf(src)
	if(cloth)
		cloth.forceMove(T)
		remove_item(cloth)
	if(holding)
		holding.forceMove(T)
		remove_item(holding)

	. = ..()

/obj/structure/bed/roller/ironingboard/proc/remove_item(obj/item/I)
	if(I == cloth)
		cloth = null
	else if(I == holding)
		holding = null

	update_icon()
	GLOB.destroyed_event.unregister(I, src, TYPE_PROC_REF(/obj/structure/bed/roller/ironingboard, remove_item))

/obj/structure/bed/roller/ironingboard/examine(mob/user)
	. = ..()
	if(cloth)
		to_chat(user, SPAN_NOTICE("\The [icon2html(cloth, user)] [cloth] lies on it."))

/obj/structure/bed/roller/ironingboard/on_update_icon()
	if(density)
		icon_state = "up"
	else
		icon_state = "down"
	if(holding)
		icon_state = "holding"

	cut_overlays()
	if(cloth)
		add_overlay(new /icon(cloth.icon, cloth.icon_state))

/obj/structure/bed/roller/ironingboard/attackby(obj/item/I, mob/user)
	if(!density)
		if(istype(I,/obj/item/clothing) || istype(I,/obj/item/ironingiron))
			to_chat(user, SPAN_NOTICE("[src] isn't deployed!"))
			return
		return ..()

	if(istype(I,/obj/item/clothing))
		if(cloth)
			to_chat(user, SPAN_NOTICE("[cloth] is already on the ironing table!"))
			return
		if(buckled_mob)
			to_chat(user, SPAN_NOTICE("[buckled_mob] is already on the ironing table!"))
			return

		if(user.unEquip(I, src))
			cloth = I
			GLOB.destroyed_event.register(I, src, TYPE_PROC_REF(/obj/structure/bed/roller/ironingboard, remove_item))
			update_icon()
		return
	else if(istype(I,/obj/item/ironingiron))
		var/obj/item/ironingiron/R = I

		// anti-wrinkle "massage"
		if(buckled_mob && ishuman(buckled_mob))
			var/mob/living/carbon/human/H = buckled_mob
			var/zone = user.zone_sel.selecting
			var/parsed = parse_zone(zone)

			visible_message(SPAN_DANGER("[user] begins ironing [src.buckled_mob]'s [parsed]!"), SPAN_DANGER("You begin ironing [buckled_mob]'s [parsed]!"))
			if(!do_after(user, 5 SECONDS, src, bonus_percentage = 25))
				return
			visible_message(SPAN_DANGER("[user] irons [src.buckled_mob]'s [parsed]!"), SPAN_DANGER("You iron [buckled_mob]'s [parsed]!"))

			var/obj/item/organ/external/affecting = H.get_organ(zone)
			affecting.take_external_damage(0, 15, used_weapon = "Hot metal")

			return

		if(!cloth)
			if(!holding && !R.enabled && user.unEquip(I, src))
				holding = R
				GLOB.destroyed_event.register(I, src, TYPE_PROC_REF(/obj/structure/bed/roller/ironingboard, remove_item))
				update_icon()
				return
			to_chat(user, SPAN_NOTICE("There isn't anything on the ironing board."))
			return

		visible_message("[user] begins ironing [cloth].")
		if(!do_after(user, 5 SECONDS, src, bonus_percentage = 25))
			return

		visible_message("[user] finishes ironing [cloth].")
		cloth.ironed_state = WRINKLES_NONE
		return

	..()

/obj/structure/bed/roller/ironingboard/attack_hand(mob/user)
	if(density) // check if it's deployed
		if(holding && user.put_in_hands(holding))
			remove_item(holding)
			return
		if(cloth && user.put_in_hands(cloth))
			remove_item(cloth)
			return
		if(!buckled_mob)
			to_chat(user, "You fold the ironing table down.")
			set_density(0)
	else
		to_chat(user, "You deploy the ironing table.")
		set_density(1)
	update_icon()
	. = ..()	//Takes care of unbuckling.

/obj/structure/bed/roller/ironingboard/collapse()
	var/turf/T = get_turf(src)
	if(cloth)
		cloth.forceMove(T)
		remove_item(cloth)
	if(holding)
		holding.forceMove(T)
		remove_item(holding)
	..()

/obj/item/roller/ironingboard
	name = "ironing board"
	desc = "A collapsed ironing board that can be carried around."
	icon = 'icons/obj/ironing.dmi'
	structure_form_type = /obj/structure/bed/roller/ironingboard
