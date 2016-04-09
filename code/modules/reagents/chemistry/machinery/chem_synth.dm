/obj/machinery/chem_dispenser/constructable/synth
	name = "Advanced chem synthesizer"
	desc = "Synthesizes advanced chemicals."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "synth"
	energy = 50
	max_energy = 50
	amount = 10
	//beaker = null
	recharge_delay = 5  //Time it game ticks between recharges
	//var/image/icon_beaker = null //cached overlay, might not be needed here.
	list/dispensable_reagents = list() //starts with no known chems

/obj/machinery/chem_dispenser/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, \
											datum/tgui/master_ui = null, datum/ui_state/state = default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "chem_dispenser", name, 550, 550, master_ui, state)
		ui.open()

/obj/machinery/chem_dispenser/ui_data()
	var/data = list()
	data["amount"] = amount
	data["energy"] = energy
	data["maxEnergy"] = max_energy
	data["isBeakerLoaded"] = beaker ? 1 : 0

	var beakerContents[0]
	var beakerCurrentVolume = 0
	if(beaker && beaker.reagents && beaker.reagents.reagent_list.len)
		for(var/datum/reagent/R in beaker.reagents.reagent_list)
			beakerContents.Add(list(list("name" = R.name, "volume" = R.volume))) // list in a list because Byond merges the first list...
			beakerCurrentVolume += R.volume
	data["beakerContents"] = beakerContents

	if (beaker)
		data["beakerCurrentVolume"] = beakerCurrentVolume
		data["beakerMaxVolume"] = beaker.volume
		data["beakerTransferAmounts"] = beaker.possible_transfer_amounts
	else
		data["beakerCurrentVolume"] = null
		data["beakerMaxVolume"] = null
		data["beakerTransferAmounts"] = null

	var chemicals[0]
	for(var/re in dispensable_reagents)
		var/datum/reagent/temp = chemical_reagents_list[re]
		if(temp)
			chemicals.Add(list(list("title" = temp.name, "id" = temp.id)))
	data["chemicals"] = chemicals
	return data

/obj/machinery/chem_dispenser/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("amount")
			var/target = text2num(params["target"])
			if(target in beaker.possible_transfer_amounts)
				amount = target
				. = TRUE
		if("dispense")
			var/reagent = params["reagent"]
			if(beaker && dispensable_reagents.Find(reagent))
				var/datum/reagents/R = beaker.reagents
				var/free = R.maximum_volume - R.total_volume
				var/actual = min(amount, energy * 10, free)

				R.add_reagent(reagent, actual)
				energy = max(energy - actual / 10, 0)
				. = TRUE
		if("remove")
			var/amount = text2num(params["amount"])
			if(beaker && amount in beaker.possible_transfer_amounts)
				beaker.reagents.remove_all(amount)
				. = TRUE
		if("eject")
			if(beaker)
				beaker.loc = loc
				beaker = null
				overlays.Cut()
				. = TRUE


/obj/machinery/chem_dispenser/constructable/synth/RefreshParts()
	var/time = 0
	var/temp_energy = 0

	for(var/obj/item/weapon/stock_parts/matter_bin/M in component_parts)
		temp_energy += M.rating
	temp_energy--
	max_energy = temp_energy * 20  //max energy = (bin1.rating + bin2.rating - 1) * 5, 20 on lowest 100 on highest
	for(var/obj/item/weapon/stock_parts/capacitor/C in component_parts)
		time += C.rating
	for(var/obj/item/weapon/stock_parts/cell/P in component_parts)
		time += round(P.maxcharge, 10000) / 10000
	recharge_delay /= time/2         //delay between recharges, double the usual time on lowest 50% less than usual on highest

/obj/machinery/chem_dispenser/constructable/synth/Topic(href, href_list)
	if(stat & (BROKEN))
		return 0 // don't update UIs attached to this object
	if(href_list["scanBeaker"])
		if(beaker)
			var/obj/item/weapon/reagent_containers/glass/B = beaker
			for(var/datum/reagent/R in B.reagents.reagent_list)
				if(R.can_synth)
					if(R.can_synth == 1 || (R.can_synth == 2 && emagged))
						add_known_reagent(R.id)
						usr << "Reagent analyzed, identified as [R.name] and added to database."
					else
						usr << "Illegal Reagent detected. NT safety regulations forbid replication of [R.name]."
				else
					usr << "Unable to scan reagent."
		return 1
	..()
	return 1

/obj/machinery/chem_dispenser/constructable/synth/proc/add_known_reagent(r_id)
	if(!(r_id in dispensable_reagents))
		dispensable_reagents += r_id
		return 1
	return 0

/obj/machinery/chem_dispenser/constructable/synth/emag_act(mob/user as mob)
	if(!emagged)
		playsound(src.loc, 'sound/effects/sparks4.ogg', 75, 1)
		emagged = 1
		user << "<span class='notice'> You you disable the safety regulation unit.</span>"