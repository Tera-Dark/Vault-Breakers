--!strict
-- Cosmetic-only, fixed CR prices. RGB data keeps this module engine-independent.
return table.freeze({
	ORDER={"CLASSIC","BRASS","ARCTIC","PLUM"},
	ITEMS={
		CLASSIC={price=0,name="style_classic"},
		BRASS={price=500,name="style_brass",rgb={242,190,82}},
		ARCTIC={price=1200,name="style_arctic",rgb={127,209,238}},
		PLUM={price=2400,name="style_plum",rgb={185,142,220}},
	},
	TITLES={"FINALIST","ONE_CREDIT","STEADY","RESOLUTE"},
})
