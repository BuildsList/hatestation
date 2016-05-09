/obj/structure/frame
	name = "frame"
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "box_0"
	density = 1
	anchored = 1
	var/obj/item/weapon/circuitboard/circuit = null
	var/state = 1

/obj/structure/frame/examine(user)
	..()
	if(circuit)
		user << "It has \a [circuit] installed."

/obj/structure/frame/machine
	name = "machine frame"
	var/list/components = null
	var/list/req_components = null
	var/list/req_component_names = null // user-friendly names of components

/obj/structure/frame/machine/examine(user)
	..()
	if(state == 3 && req_components && req_component_names)
		var/hasContent = 0
		var/requires = "It requires"

		for(var/i = 1 to req_components.len)
			var/tname = req_components[i]
			var/amt = req_components[tname]
			if(amt == 0)
				continue
			var/use_and = i == req_components.len
			requires += "[(hasContent ? (use_and ? ", and" : ",") : "")] [amt] [amt == 1 ? req_component_names[tname] : "[req_component_names[tname]]\s"]"
			hasContent = 1

		if(hasContent)
			user << requires + "."
		else
			user << "It does not require any more components."

/obj/structure/frame/machine/proc/update_namelist()
	if(!req_components)
		return

	req_component_names = new()
	for(var/tname in req_components)
		if(ispath(tname, /obj/item/stack))
			var/obj/item/stack/S = tname
			var/singular_name = initial(S.singular_name)
			if(singular_name)
				req_component_names[tname] = singular_name
			else
				req_component_names[tname] = initial(S.name)
		else
			var/obj/O = tname
			req_component_names[tname] = initial(O.name)

/obj/structure/frame/machine/proc/get_req_components_amt()
	var/amt = 0
	for(var/path in req_components)
		amt += req_components[path]
	return amt

/obj/structure/frame/machine/attackby(obj/item/P, mob/user, params)
	if(P.crit_fail)
		user << "<span class='warning'>This part is faulty, you cannot add this to the machine!</span>"
		return
	switch(state)
		if(1)
			if(istype(P, /obj/item/weapon/circuitboard/machine))
				user << "<span class='warning'>The frame needs wiring first!</span>"

			else if(istype(P, /obj/item/weapon/circuitboard))
				user << "<span class='warning'>This frame does not accept circuit boards of this type!</span>"

			if(istype(P, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/C = P
				if(C.get_amount() >= 5)
					playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
					user << "<span class='notice'>You start to add cables to the frame...</span>"
					if(do_after(user, 20/P.toolspeed, target = src))
						if(C.get_amount() >= 5 && state == 1)
							C.use(5)
							user << "<span class='notice'>You add cables to the frame.</span>"
							state = 2
							icon_state = "box_1"
				else
					user << "<span class='warning'>You need five length of cable to wire the frame!</span>"
					return
			if(istype(P, /obj/item/weapon/screwdriver) && !anchored)
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
				user.visible_message("<span class='warning'>[user] disassembles the frame.</span>", \
									"<span class='notice'>You start to disassemble the frame...</span>", "You hear banging and clanking.")
				if(do_after(user, 40/P.toolspeed, target = src))
					if(state == 1)
						user << "<span class='notice'>You disassemble the frame.</span>"
						var/obj/item/stack/sheet/metal/M = new (loc, 5)
						M.add_fingerprint(user)
						qdel(src)
			if(istype(P, /obj/item/weapon/wrench))
				user << "<span class='notice'>You start [anchored ? "un" : ""]securing [name]...</span>"
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				if(do_after(user, 40/P.toolspeed, target = src))
					if(state == 1)
						user << "<span class='notice'>You [anchored ? "un" : ""]secure [name].</span>"
						anchored = !anchored

		if(2)
			if(istype(P, /obj/item/weapon/wrench))
				user << "<span class='notice'>You start [anchored ? "un" : ""]securing [name]...</span>"
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				if(do_after(user, 40/P.toolspeed, target = src))
					user << "<span class='notice'>You [anchored ? "un" : ""]secure [name].</span>"
					anchored = !anchored

			if(istype(P, /obj/item/weapon/circuitboard/machine))
				if(!anchored)
					user << "<span class='warning'>The frame needs to be secured first!</span>"
					return
				var/obj/item/weapon/circuitboard/machine/B = P
				if(!user.drop_item())
					return
				playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
				user << "<span class='notice'>You add the circuit board to the frame.</span>"
				circuit = B
				B.loc = src
				icon_state = "box_2"
				state = 3
				components = list()
				req_components = B.req_components.Copy()
				update_namelist()

			else if(istype(P, /obj/item/weapon/circuitboard))
				user << "<span class='warning'>This frame does not accept circuit boards of this type!</span>"

			if(istype(P, /obj/item/weapon/wirecutters))
				playsound(src.loc, 'sound/items/Wirecutter.ogg', 50, 1)
				user << "<span class='notice'>You remove the cables.</span>"
				state = 1
				icon_state = "box_0"
				var/obj/item/stack/cable_coil/A = new /obj/item/stack/cable_coil( src.loc )
				A.amount = 5

		if(3)
			if(istype(P, /obj/item/weapon/crowbar))
				playsound(src.loc, 'sound/items/Crowbar.ogg', 50, 1)
				state = 2
				circuit.loc = src.loc
				components.Remove(circuit)
				circuit = null
				if(components.len == 0)
					user << "<span class='notice'>You remove the circuit board.</span>"
				else
					user << "<span class='notice'>You remove the circuit board and other components.</span>"
					for(var/atom/movable/A in components)
						A.loc = src.loc
				desc = initial(desc)
				req_components = null
				components = null
				icon_state = "box_1"

			if(istype(P, /obj/item/weapon/screwdriver))
				var/component_check = 1
				for(var/R in req_components)
					if(req_components[R] > 0)
						component_check = 0
						break
				if(component_check)
					playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
					var/obj/machinery/new_machine = new src.circuit.build_path(src.loc, 1)
					new_machine.construction()
					for(var/obj/O in new_machine.component_parts)
						qdel(O)
					new_machine.component_parts = list()
					for(var/obj/O in src)
						O.loc = null
						new_machine.component_parts += O
					circuit.loc = null
					new_machine.RefreshParts()
					qdel(src)

			if(istype(P, /obj/item/weapon/storage/part_replacer) && P.contents.len && get_req_components_amt())
				var/obj/item/weapon/storage/part_replacer/replacer = P
				var/list/added_components = list()
				var/list/part_list = list()

				//Assemble a list of current parts, then sort them by their rating!
				for(var/obj/item/weapon/stock_parts/co in replacer)
					part_list += co
				//Sort the parts. This ensures that higher tier items are applied first.
				part_list = sortTim(part_list, /proc/cmp_rped_sort)

				for(var/path in req_components)
					while(req_components[path] > 0 && (locate(path) in part_list))
						var/obj/item/part = (locate(path) in part_list)
						if(!part.crit_fail)
							added_components[part] = path
							replacer.remove_from_storage(part, src)
							req_components[path]--
							part_list -= part

				for(var/obj/item/weapon/stock_parts/part in added_components)
					components += part
					user << "<span class='notice'>[part.name] applied.</span>"
				if(added_components.len)
					replacer.play_rped_sound()
				return

			if(istype(P, /obj/item) && get_req_components_amt())
				for(var/I in req_components)
					if(istype(P, I) && (req_components[I] > 0))
						if(istype(P, /obj/item/stack))
							var/obj/item/stack/S = P
							var/used_amt = min(round(S.get_amount()), req_components[I])

							if(used_amt && S.use(used_amt))
								var/obj/item/stack/NS = locate(S.merge_type) in components

								if(!NS)
									NS = new S.merge_type(src, used_amt)
									components += NS
								else
									NS.add(used_amt)

								req_components[I] -= used_amt
								user << "<span class='notice'>You add [P] to [src].</span>"
							return
						if(!user.drop_item())
							break
						user << "<span class='notice'>You add [P] to [src].</span>"
						P.loc = src
						components += P
						req_components[I]--
						return 1
				user << "<span class='warning'>You cannot add that to the machine!</span>"
				return 0


//Machine Frame Circuit Boards
/*Common Parts: Parts List: Ignitor, Timer, Infra-red laser, Infra-red sensor, t_scanner, Capacitor, Valve, sensor unit,
micro-manipulator, console screen, beaker, Microlaser, matter bin, power cells.
*/

<<<<<<< HEAD
/obj/item/weapon/circuitboard/chem_dispenser
	name = "circuit board (Portable Chem Dispenser)"
	desc = "Use screwdriver to switch between dispenser modes."
	build_path = /obj/machinery/chem_dispenser/constructable
	board_type = "machine"
	var/finish_type = "chemical dispenser"
	origin_tech = "materials=4;engineering=4;programming=4;plasmatech=3;biotech=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/cell = 1)

/obj/item/weapon/circuitboard/chem_dispenser/attackby(obj/item/I as obj, mob/user as mob, params)
	if(istype(I,/obj/item/weapon/screwdriver))
		var/board_choice = input("Current mode is set to: [finish_type]","Circuitboard interface") in list("Advanced Chem Synthesizer","Chemical Dispenser", "Booze Dispenser", "Soda Dispenser", "Cancel")
		switch( board_choice )
			if("Advanced Chem Synthesizer")
				name = "circuit board (Advanced Chem Synthesizer)"
				build_path = /obj/machinery/chem_dispenser/constructable/synth
				finish_type = "advanced chem synthesizer"
				return
			if("Chemical Dispenser")
				name = "circuit board (Portable Chem Dispenser)"
				build_path = /obj/machinery/chem_dispenser/constructable
				finish_type = "chemical dispenser"
				return
			if("Cancel")
				return
			else
				user << "[board_choice]: Invalid input, try again"
	return

/obj/item/weapon/circuitboard/vendor
	name = "circuit board (Booze-O-Mat Vendor)"
	build_path = /obj/machinery/vending/boozeomat
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/vending_refill/boozeomat = 3)

	var/list/names_paths = list(/obj/machinery/vending/boozeomat = "Booze-O-Mat",
							/obj/machinery/vending/coffee = "Solar's Best Hot Drinks",
							/obj/machinery/vending/snack = "Getmore Chocolate Corp",
							/obj/machinery/vending/cola = "Robust Softdrinks",
							/obj/machinery/vending/cigarette = "ShadyCigs Deluxe",
							/obj/machinery/vending/autodrobe = "AutoDrobe")

/obj/item/weapon/circuitboard/vendor/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/screwdriver))
		set_type(pick(names_paths), user)


/obj/item/weapon/circuitboard/vendor/proc/set_type(typepath, mob/user)
		build_path = typepath
		name = "circuit board ([names_paths[build_path]] Vendor)"
		user << "<span class='notice'>You set the board to [names_paths[build_path]].</span>"
		req_components = list(text2path("/obj/item/weapon/vending_refill/[copytext("[build_path]", 24)]") = 3)       //Never before has i used a method as horrible as this one, im so sorry

/obj/item/weapon/circuitboard/announcement_system
	name = "circuit board (Announcement System)"
	build_path = /obj/machinery/announcement_system
	board_type = "machine"
	origin_tech = "programming=3;bluespace=2"
	req_components = list(
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)
=======
/obj/item/weapon/circuitboard/machine
	var/list/req_components = null

/obj/item/weapon/circuitboard/machine/proc/apply_default_parts(obj/machinery/M)
	if(!req_components)
		return

	M.component_parts = list(src)
	loc = null
>>>>>>> refs/remotes/upstream/master

	for(var/comp_path in req_components)
		var/comp_amt = req_components[comp_path]
		if(!comp_amt)
			continue

		if(ispath(comp_path, /obj/item/stack))
			M.component_parts += new comp_path(null, comp_amt)
		else
			for(var/i in 1 to comp_amt)
				M.component_parts += new comp_path(null)

	M.RefreshParts()


/obj/item/weapon/circuitboard/machine/smes
	name = "circuit board (SMES)"
	build_path = /obj/machinery/power/smes
	origin_tech = "programming=4;powerstorage=5;engineering=5"
	req_components = list(
							/obj/item/stack/cable_coil = 5,
							/obj/item/weapon/stock_parts/cell = 5,
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/machine/teleporter_hub
	name = "circuit board (Teleporter Hub)"
	build_path = /obj/machinery/teleport/hub
	origin_tech = "programming=3;engineering=5;bluespace=5;materials=4"
	req_components = list(
							/obj/item/weapon/ore/bluespace_crystal = 3,
							/obj/item/weapon/stock_parts/matter_bin = 1)

/obj/item/weapon/circuitboard/machine/teleporter_station
	name = "circuit board (Teleporter Station)"
	build_path = /obj/machinery/teleport/station
	origin_tech = "programming=4;engineering=4;bluespace=4"
	req_components = list(
							/obj/item/weapon/ore/bluespace_crystal = 2,
							/obj/item/weapon/stock_parts/capacitor = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

<<<<<<< HEAD
/obj/item/weapon/circuitboard/telesci_pad
	name = "circuit board (Telepad)"
	build_path = /obj/machinery/telepad
	board_type = "machine"
	origin_tech = "programming=4;engineering=3;materials=3;bluespace=4"
	req_components = list(
							/obj/item/weapon/ore/bluespace_crystal = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/sleeper
	name = "circuit board (Sleeper)"
	build_path = /obj/machinery/sleeper
	board_type = "machine"
	origin_tech = "programming=3;biotech=2;engineering=3;materials=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 2)

/obj/item/weapon/circuitboard/cryo_tube
	name = "circuit board (Cryotube)"
	build_path = /obj/machinery/atmospherics/components/unary/cryo_cell
	board_type = "machine"
	origin_tech = "programming=4;biotech=3;engineering=4"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 4)

/obj/item/weapon/circuitboard/thermomachine
	name = "circuit board (Thermomachine)"
	desc = "You can use a screwdriver to switch between heater and freezer."
	board_type = "machine"
	origin_tech = "programming=3;plasmatech=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/micro_laser = 2,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/thermomachine/attackby(obj/item/I, mob/user, params)
	var/obj/item/weapon/circuitboard/freezer = /obj/item/weapon/circuitboard/thermomachine/freezer
	var/obj/item/weapon/circuitboard/heater = /obj/item/weapon/circuitboard/thermomachine/heater
	var/obj/item/weapon/circuitboard/newtype

	if(istype(I, /obj/item/weapon/screwdriver))
		if(build_path == initial(heater.build_path))
			newtype = freezer
		else
			newtype = heater
		name = initial(newtype.name)
		build_path = initial(newtype.build_path)

/obj/item/weapon/circuitboard/thermomachine/freezer
	name = "circuit board (Freezer)"
	build_path = /obj/machinery/atmospherics/components/unary/thermomachine/freezer

/obj/item/weapon/circuitboard/thermomachine/heater
	name = "circuit board (Heater)"
	build_path = /obj/machinery/atmospherics/components/unary/thermomachine/heater

/obj/item/weapon/circuitboard/space_heater
	name = "circuit board (Space Heater)"
	build_path = /obj/machinery/space_heater
	board_type = "machine"
	origin_tech = "programming=2;engineering=2"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/stack/cable_coil = 3)

/obj/item/weapon/circuitboard/biogenerator
	name = "circuit board (Biogenerator)"
	build_path = /obj/machinery/biogenerator
	board_type = "machine"
	origin_tech = "programming=3;biotech=2;materials=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/hydroponics
	name = "circuit board (Hydroponics Tray)"
	build_path = /obj/machinery/hydroponics/constructable
	board_type = "machine"
	origin_tech = "programming=1;biotech=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/microwave
	name = "circuit board (Microwave)"
	build_path = /obj/machinery/microwave
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/item/weapon/circuitboard/deepfryer
	name = "circuit board (Deep Fryer)"
	build_path = /obj/machinery/cooking/deepfryer
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/stack/cable_coil = 2,
							/obj/item/weapon/stock_parts/matter_bin = 1,)

/obj/item/weapon/circuitboard/gibber
	name = "circuit board (Gibber)"
	build_path = /obj/machinery/gibber
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/extraction_point
	name = "circuit board (Balloon Extraction Point)"
	build_path = /obj/machinery/extraction_point
	board_type = "machine"
	origin_tech = "programming=4"
	req_components = list(
							/obj/item/weapon/stock_parts/scanning_module = 1)

/obj/item/weapon/circuitboard/tesla_coil
	name = "circuit board (Tesla Coil)"
	build_path = /obj/machinery/power/tesla_coil
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/grounding_rod
	name = "circuit board (Grounding Rod)"
	build_path = /obj/machinery/power/grounding_rod
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/processor
	name = "circuit board (Food processor)"
	build_path = /obj/machinery/processor
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/recycler
	name = "circuit board (Recycler)"
	build_path = /obj/machinery/recycler
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/seed_extractor
	name = "circuit board (Seed Extractor)"
	build_path = /obj/machinery/seed_extractor
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/smartfridge
	name = "circuit board (Smartfridge)"
	build_path = /obj/machinery/smartfridge
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1)

/obj/item/weapon/circuitboard/smartfridge/New(loc, new_type)
	if(new_type)
		build_path = new_type

/obj/item/weapon/circuitboard/smartfridge/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/screwdriver))
		var/list/fridges = list(/obj/machinery/smartfridge = "default",
									 /obj/machinery/smartfridge/drinks = "drinks",
									 /obj/machinery/smartfridge/extract = "slimes",
									 /obj/machinery/smartfridge/chemistry = "chems",
									 /obj/machinery/smartfridge/chemistry/virology = "viruses")

		var/position = fridges.Find(build_path, fridges)
		position = (position == fridges.len) ? 1 : (position + 1)
		build_path = fridges[position]
		user << "<span class='notice'>You set the board to [fridges[build_path]].</span>"

/obj/item/weapon/circuitboard/monkey_recycler
	name = "circuit board (Monkey Recycler)"
	build_path = /obj/machinery/monkey_recycler
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/holopad
	name = "circuit board (AI Holopad)"
	build_path = /obj/machinery/hologram/holopad
	board_type = "machine"
	origin_tech = "programming=1"
	req_components = list(
							/obj/item/weapon/stock_parts/capacitor = 1)

/obj/item/weapon/circuitboard/chem_dispenser
=======
/obj/item/weapon/circuitboard/machine/chem_dispenser
>>>>>>> refs/remotes/upstream/master
	name = "circuit board (Portable Chem Dispenser)"
	build_path = /obj/machinery/chem_dispenser/constructable
	origin_tech = "materials=4;engineering=4;programming=4;plasmatech=3;biotech=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/cell = 1)

/obj/item/weapon/circuitboard/machine/telesci_pad
	name = "circuit board (Telepad)"
	build_path = /obj/machinery/telepad
	origin_tech = "programming=4;engineering=3;materials=3;bluespace=4"
	req_components = list(
							/obj/item/weapon/ore/bluespace_crystal = 2,
							/obj/item/weapon/stock_parts/capacitor = 1,
							/obj/item/stack/cable_coil = 1,
<<<<<<< HEAD
							/obj/item/weapon/stock_parts/subspace/filter = 1,
							/obj/item/weapon/stock_parts/subspace/crystal = 1,
							/obj/item/weapon/stock_parts/micro_laser/high = 2)
/obj/item/weapon/circuitboard/ore_redemption
	name = "circuit board (Ore Redemption)"
	build_path = /obj/machinery/mineral/ore_redemption
	board_type = "machine"
	origin_tech = "programming=1;engineering=2"
	req_components = list(
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/matter_bin = 1,
							/obj/item/weapon/stock_parts/micro_laser = 1,
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/device/assembly/igniter = 1)

/obj/item/weapon/circuitboard/mining_equipment_vendor
	name = "circuit board (Mining Equipment Vendor)"
	build_path = /obj/machinery/mineral/equipment_vendor
	board_type = "machine"
	origin_tech = "programming=1;engineering=2"
	req_components = list(
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/matter_bin = 3)

/obj/item/weapon/circuitboard/mining_equipment_vendor/golem
	name = "circuit board (Golem Ship Equipment Vendor)"
	build_path = /obj/machinery/mineral/equipment_vendor/golem

/obj/item/weapon/circuitboard/plantgenes
	name = "circuit board (Plant DNA Manipulator)"
	build_path = /obj/machinery/plantgenes
	board_type = "machine"
	origin_tech = "programming=2;biotech=3"
	req_components = list(
							/obj/item/weapon/stock_parts/manipulator = 1,
							/obj/item/weapon/stock_parts/micro_laser = 2,
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/weapon/stock_parts/scanning_module = 1,)
=======
							/obj/item/weapon/stock_parts/console_screen = 1)
>>>>>>> refs/remotes/upstream/master
