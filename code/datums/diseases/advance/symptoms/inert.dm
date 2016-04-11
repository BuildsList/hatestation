/*
//////////////////////////////////////

Inert Virus

	Base Symptom for Pandemic mutations.
	Lowers resistance tremendously.
	Decreases stage tremendously.
	Decreases transmittablity tremendously.
	Fatal Level. Can kill with boredom.

Bonus
	Disapears after Virus gets another symptom.

//////////////////////////////////////
*/

/datum/symptom/inert_virus

	name = "Inert Virus"
	stealth = 0
	resistance = 0
	stage_speed = 0
	transmittable = 0
	level = 10
	severity = 0

/datum/symptom/inert_virus/Activate(datum/disease/advance/A)
	..()
	return
